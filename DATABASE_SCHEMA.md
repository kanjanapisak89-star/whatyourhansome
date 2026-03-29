# Content-to-Customer Platform - Database Schema

## Overview
This schema supports a content platform where owners/admins post content, and users (guests/members) can interact through reactions, comments, and board questions.

## Entity Relationship Diagram (Conceptual)

```
┌─────────────┐
│   USERS     │
│ (Firebase)  │
└──────┬──────┘
       │
       ├──────────────┬──────────────┬──────────────┬──────────────┐
       │              │              │              │              │
       ▼              ▼              ▼              ▼              ▼
  ┌─────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
  │  POSTS  │   │REACTIONS │   │ COMMENTS │   │  BOARD   │   │  AUDIT   │
  │(Content)│   │ (Likes)  │   │(Feedback)│   │QUESTIONS │   │   LOGS   │
  └─────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
       │              │              │
       └──────────────┴──────────────┘
                      │
                ┌─────────────┐
                │ POST_STATS  │
                │(Materialized│
                │    View)    │
                └─────────────┘
```

## Tables

### 1. `users`
Stores all user accounts (Firebase Auth integration).

**Columns:**
- `id` (UUID, PK): Internal user ID
- `firebase_uid` (VARCHAR, UNIQUE): Firebase Authentication UID
- `email` (VARCHAR, UNIQUE): User email
- `display_name` (VARCHAR): Display name from OAuth provider
- `avatar_url` (TEXT): Profile picture URL
- `provider` (VARCHAR): 'google' or 'facebook'
- `role` (ENUM): 'guest', 'member', 'admin', 'owner'
- `status` (ENUM): 'active', 'blocked', 'deleted'
- `created_at`, `updated_at`, `last_login_at` (TIMESTAMPTZ)

**Key Features:**
- Firebase UID is the primary authentication identifier
- Role-based access control (RBAC)
- Soft delete via `status` field
- Tracks last login for analytics

**Indexes:**
- `firebase_uid` (for auth lookups)
- `email` (for user search)
- `status` (for filtering blocked users)

---

### 2. `posts`
Content created by owners/admins (like Marcus Thorne's posts in the UI).

**Columns:**
- `id` (UUID, PK): Post identifier
- `author_id` (UUID, FK → users): Content creator
- `title` (VARCHAR): Post headline (e.g., "The Obsidian Shift")
- `content` (TEXT): Full post body
- `image_url` (TEXT): Featured image URL
- `published` (BOOLEAN): Draft vs. published state
- `view_count` (INTEGER): Track post views
- `created_at`, `updated_at` (TIMESTAMPTZ)

**Key Features:**
- Only admins/owners can create posts
- Supports draft mode (`published = false`)
- View tracking for analytics

**Indexes:**
- `author_id` (for author's post list)
- `published` (for filtering published content)
- `created_at DESC` (for chronological feed)

---

### 3. `reactions`
Tracks likes/hearts on posts (the "19", "38", "53" counts in the UI).

**Columns:**
- `id` (UUID, PK): Reaction identifier
- `user_id` (UUID, FK → users): Who reacted
- `post_id` (UUID, FK → posts): Which post
- `created_at` (TIMESTAMPTZ): When reacted

**Key Features:**
- `UNIQUE(user_id, post_id)`: One reaction per user per post
- Cascade delete when user/post is deleted
- Simple like/unlike toggle

**Indexes:**
- `post_id` (for counting reactions per post)
- `user_id` (for user's reaction history)

---

### 4. `comments`
User feedback on posts (the "84", "166", "410" counts in the UI).

**Columns:**
- `id` (UUID, PK): Comment identifier
- `post_id` (UUID, FK → posts): Which post
- `user_id` (UUID, FK → users): Comment author
- `content` (TEXT): Comment text
- `is_deleted` (BOOLEAN): Soft delete flag
- `deleted_by` (UUID, FK → users): Admin who deleted
- `deleted_at` (TIMESTAMPTZ): Deletion timestamp
- `created_at`, `updated_at` (TIMESTAMPTZ)

**Key Features:**
- Soft delete for moderation (admins can delete inappropriate comments)
- Tracks who deleted the comment (audit trail)
- Supports comment editing via `updated_at`

**Indexes:**
- `post_id` (for fetching post comments)
- `user_id` (for user's comment history)
- `created_at DESC` (for chronological order)

---

### 5. `board_questions`
User-submitted questions/requests to the "Board" section.

**Columns:**
- `id` (UUID, PK): Question identifier
- `user_id` (UUID, FK → users): Who asked
- `title` (VARCHAR): Question headline
- `content` (TEXT): Full question body
- `status` (VARCHAR): 'pending', 'answered', 'archived'
- `admin_response` (TEXT): Owner's response
- `responded_by` (UUID, FK → users): Admin who responded
- `responded_at` (TIMESTAMPTZ): Response timestamp
- `created_at`, `updated_at` (TIMESTAMPTZ)

**Key Features:**
- Members can post questions
- Admins can respond and change status
- Tracks response history

**Indexes:**
- `user_id` (for user's question history)
- `status` (for filtering pending questions)
- `created_at DESC` (for chronological order)

---

### 6. `post_stats` (Materialized View)
Pre-computed aggregates for performance (reaction/comment counts).

**Columns:**
- `post_id` (UUID): Post identifier
- `reaction_count` (BIGINT): Total likes
- `comment_count` (BIGINT): Total non-deleted comments
- `view_count` (INTEGER): Total views

**Key Features:**
- Auto-refreshes on reaction/comment changes (via triggers)
- Eliminates expensive COUNT queries on feed load
- Uses `CONCURRENTLY` for non-blocking refreshes

**Why Materialized View?**
- Feed queries need counts for every post (expensive joins)
- This view pre-computes counts for instant retrieval
- Triggers keep it up-to-date automatically

---

### 7. `audit_logs`
Tracks admin actions for compliance and debugging.

**Columns:**
- `id` (UUID, PK): Log entry identifier
- `admin_id` (UUID, FK → users): Who performed action
- `action` (VARCHAR): 'block_user', 'delete_comment', etc.
- `target_type` (VARCHAR): 'user', 'comment', 'post'
- `target_id` (UUID): ID of affected entity
- `metadata` (JSONB): Additional context (e.g., reason)
- `created_at` (TIMESTAMPTZ): When action occurred

**Key Features:**
- Immutable log (no updates/deletes)
- JSONB for flexible metadata storage
- Supports compliance audits

**Indexes:**
- `admin_id` (for admin activity reports)
- `created_at DESC` (for recent actions)

---

## Access Control Matrix

| Role   | Read Posts | React | Comment | Post Question | Create Post | Delete Comment | Block User |
|--------|-----------|-------|---------|---------------|-------------|----------------|------------|
| Guest  | ✅        | ❌    | ❌      | ❌            | ❌          | ❌             | ❌         |
| Member | ✅        | ✅    | ✅      | ✅            | ❌          | ❌             | ❌         |
| Admin  | ✅        | ✅    | ✅      | ✅            | ✅          | ✅             | ✅         |
| Owner  | ✅        | ✅    | ✅      | ✅            | ✅          | ✅             | ✅         |

---

## Key Design Decisions

### 1. Firebase UID vs. Internal UUID
- **Firebase UID**: Used for authentication (JWT validation)
- **Internal UUID**: Used for all foreign keys (decouples auth from data model)
- **Why?** If you switch auth providers later, only the `users` table changes

### 2. Soft Deletes
- Comments use `is_deleted` flag instead of hard delete
- Users use `status = 'deleted'` instead of DROP
- **Why?** Preserves data integrity and enables "undo" functionality

### 3. Materialized View for Stats
- Alternative: Compute counts on every feed load (slow)
- **Why Materialized View?** Pre-computed counts = instant feed loads
- **Trade-off:** Slight delay in count updates (acceptable for social feeds)

### 4. JSONB for Audit Metadata
- Flexible schema for different action types
- Example: `{"reason": "spam", "reported_by": "user_id"}`
- **Why?** Avoids creating separate tables for each action type

---

## Performance Optimizations

1. **Indexes on Foreign Keys**: All FK columns have indexes for fast joins
2. **Composite Unique Index**: `reactions(user_id, post_id)` prevents duplicate likes
3. **Partial Indexes**: Could add `WHERE is_deleted = false` on comments (future optimization)
4. **Materialized View**: Eliminates COUNT queries on feed loads
5. **Timestamp Indexes**: `created_at DESC` for chronological queries

---

## Migration Strategy

### Initial Setup
```bash
# Run migrations
cd backend
go run cmd/migrate/main.go up

# Or using migrate CLI
migrate -path migrations -database "postgresql://user:pass@localhost:5432/loft?sslmode=disable" up
```

### Rollback
```bash
migrate -path migrations -database "postgresql://..." down 1
```

---

## Next Steps

1. **Generate Type-Safe Queries**: Use `sqlc` to generate Go code from SQL
2. **Seed Data**: Create sample posts/users for testing
3. **API Design**: Define Protobuf messages matching this schema
4. **Frontend Models**: Generate Dart classes from Protobuf definitions

---

## Example Queries

### Get Feed with Stats
```sql
SELECT 
    p.id, p.title, p.content, p.image_url, p.created_at,
    u.display_name, u.avatar_url,
    ps.reaction_count, ps.comment_count, ps.view_count,
    EXISTS(SELECT 1 FROM reactions WHERE post_id = p.id AND user_id = $1) AS user_has_reacted
FROM posts p
JOIN users u ON p.author_id = u.id
JOIN post_stats ps ON p.id = ps.post_id
WHERE p.published = true
ORDER BY p.created_at DESC
LIMIT 20;
```

### Block User (Admin Action)
```sql
BEGIN;
UPDATE users SET status = 'blocked' WHERE id = $1;
INSERT INTO audit_logs (admin_id, action, target_type, target_id, metadata)
VALUES ($2, 'block_user', 'user', $1, '{"reason": "spam"}');
COMMIT;
```

### Get User's Reaction Status
```sql
SELECT post_id 
FROM reactions 
WHERE user_id = $1 AND post_id = ANY($2);
```

---

## Schema Validation Checklist

- ✅ Supports guest vs. member access control
- ✅ Tracks reactions (likes) with uniqueness constraint
- ✅ Supports comment moderation (soft delete)
- ✅ Board questions with admin responses
- ✅ Audit trail for admin actions
- ✅ Performance-optimized with materialized view
- ✅ Firebase Auth integration via `firebase_uid`
- ✅ Timestamps for all entities
- ✅ Cascade deletes where appropriate
- ✅ Indexes on all foreign keys and query patterns
