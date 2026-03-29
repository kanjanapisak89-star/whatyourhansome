# Content-to-Customer Platform - Implementation Plan

## ✅ Completed

### 1. Database Schema
- ✅ Created migration files (`000002_content_platform.up/down.sql`)
- ✅ Tables: users, posts, reactions, comments, board_questions, audit_logs
- ✅ Materialized view for post stats (performance optimization)
- ✅ Indexes and triggers configured
- ✅ Documentation in `DATABASE_SCHEMA.md`

### 2. Backend API (Protobuf)
- ✅ Updated `backend/proto/loft/v1/loft.proto` with:
  - 4 services: PublicService, MemberService, AdminService, AuthService
  - Complete CRUD operations for posts, comments, reactions, board questions
  - User management (block/unblock)
  - Role-based access control

### 3. Backend Services (Golang)
- ✅ Service implementations created:
  - `public_service.go` - Guest-accessible endpoints
  - `member_service.go` - Authenticated user endpoints
  - `admin_service.go` - Admin/owner endpoints
  - `auth_service.go` - User sync with Firebase
  - `context.go` - Context helpers for auth
- ✅ SQL queries defined in `internal/db/queries/`
- ✅ sqlc configuration for type-safe queries

## 🚧 Next Steps

### Phase 1: Backend Completion (30 min)
1. Run database migrations
2. Generate protobuf code (`buf generate` or `protoc`)
3. Generate sqlc code
4. Complete service implementations with real DB queries
5. Test endpoints with curl/Postman

### Phase 2: Flutter App Setup (45 min)
1. Create Flutter project structure
2. Configure dependencies:
   - riverpod + riverpod_generator
   - dio (HTTP client)
   - firebase_auth
   - cached_network_image
   - flutter_screenutil
   - lucide_icons
3. Generate protobuf Dart code
4. Setup Riverpod providers

### Phase 3: Flutter UI Implementation (2 hours)
1. **Auth Flow**
   - Login screen with Google/Facebook buttons
   - Firebase Auth integration
   - User sync with backend

2. **Feed Screen** (Main UI from image_0.png)
   - Post list with infinite scroll
   - Post card component matching design
   - Like/comment counts
   - Shimmer loading states

3. **Post Detail Screen**
   - Full post content
   - Comments section
   - Like/comment interactions

4. **Board Screen**
   - Question submission form
   - User's question history

5. **Profile Screen**
   - User info
   - Logout

### Phase 4: Admin/Backoffice (1 hour)
1. **Admin Web Panel** (Flutter Web or separate)
   - Post creation/editing
   - User management (block/unblock)
   - Comment moderation
   - Board question responses

### Phase 5: Deployment (30 min)
1. **Backend to Railway**
   - Configure `railway.json`
   - Set environment variables
   - Deploy PostgreSQL + Go server

2. **Flutter App**
   - Configure app icons/splash
   - Build APK/IPA
   - Test on device

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      FLUTTER APP                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Feed Screen │  │ Board Screen │  │Profile Screen│      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                   ┌────────▼────────┐                        │
│                   │ Riverpod State  │                        │
│                   │   Management    │                        │
│                   └────────┬────────┘                        │
│                            │                                 │
│                   ┌────────▼────────┐                        │
│                   │  Connect-RPC    │                        │
│                   │     Client      │                        │
│                   └────────┬────────┘                        │
└────────────────────────────┼────────────────────────────────┘
                             │ HTTPS
                             │
┌────────────────────────────▼────────────────────────────────┐
│                    GOLANG BACKEND                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Public     │  │   Member     │  │    Admin     │      │
│  │   Service    │  │   Service    │  │   Service    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                   ┌────────▼────────┐                        │
│                   │  Auth Middleware│                        │
│                   │  (Firebase JWT) │                        │
│                   └────────┬────────┘                        │
│                            │                                 │
│                   ┌────────▼────────┐                        │
│                   │   PostgreSQL    │                        │
│                   │    (Railway)    │                        │
│                   └─────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## API Endpoints Summary

### Public (No Auth)
- `GET /loft.v1.PublicService/GetFeed` - List posts
- `GET /loft.v1.PublicService/GetPost` - Single post
- `GET /loft.v1.PublicService/GetComments` - Post comments

### Member (Auth Required)
- `POST /loft.v1.MemberService/ToggleReaction` - Like/unlike
- `POST /loft.v1.MemberService/CreateComment` - Add comment
- `POST /loft.v1.MemberService/CreateBoardQuestion` - Submit question
- `GET /loft.v1.MemberService/GetMyQuestions` - User's questions
- `GET /loft.v1.MemberService/GetCurrentUser` - Profile

### Admin (Admin Role Required)
- `POST /loft.v1.AdminService/CreatePost` - New post
- `PUT /loft.v1.AdminService/UpdatePost` - Edit post
- `DELETE /loft.v1.AdminService/DeletePost` - Remove post
- `DELETE /loft.v1.AdminService/DeleteComment` - Moderate comment
- `POST /loft.v1.AdminService/BlockUser` - Block user
- `POST /loft.v1.AdminService/UnblockUser` - Unblock user
- `GET /loft.v1.AdminService/GetBoardQuestions` - All questions
- `POST /loft.v1.AdminService/RespondToQuestion` - Answer question

### Auth
- `POST /loft.v1.AuthService/SyncUser` - Sync Firebase user

## Environment Variables

### Backend
```bash
DATABASE_URL=postgresql://user:pass@host:5432/loft
PORT=8080
GOOGLE_APPLICATION_CREDENTIALS=/path/to/firebase-admin-sdk.json
```

### Flutter
```bash
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
API_BASE_URL=https://your-backend.railway.app
```

## Testing Strategy

1. **Backend Unit Tests**
   - Service layer tests
   - Database query tests

2. **Integration Tests**
   - API endpoint tests
   - Auth flow tests

3. **Flutter Widget Tests**
   - UI component tests
   - State management tests

4. **E2E Tests**
   - User flows (login → browse → like → comment)
   - Admin flows (create post → moderate)

## Performance Targets

- Feed load time: < 500ms
- Post detail load: < 300ms
- Like/comment action: < 200ms
- Image loading: Progressive with cache
- Offline support: Read-only cached content

## Security Checklist

- ✅ Firebase JWT validation on all protected endpoints
- ✅ Role-based access control (RBAC)
- ✅ SQL injection prevention (parameterized queries)
- ✅ CORS configuration
- ✅ Rate limiting (TODO)
- ✅ Input validation (TODO)
- ✅ XSS prevention (TODO)
