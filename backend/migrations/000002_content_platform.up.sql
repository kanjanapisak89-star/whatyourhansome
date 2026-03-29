-- =====================================================
-- Content-to-Customer Platform Schema
-- Supports: Posts, Reactions, Comments, Board Questions
-- =====================================================

-- User Roles Enum
CREATE TYPE user_role AS ENUM ('guest', 'member', 'admin', 'owner');

-- User Status Enum
CREATE TYPE user_status AS ENUM ('active', 'blocked', 'deleted');

-- Content Type Enum
CREATE TYPE content_type AS ENUM ('post', 'board_question');

-- =====================================================
-- USERS TABLE
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    provider VARCHAR(20) NOT NULL, -- 'google', 'facebook'
    role user_role DEFAULT 'member',
    status user_status DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- =====================================================
-- POSTS TABLE (Owner/Admin Content)
-- =====================================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    published BOOLEAN DEFAULT true,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_published ON posts(published);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- =====================================================
-- REACTIONS TABLE (Likes/Hearts)
-- =====================================================
CREATE TABLE reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, post_id) -- One reaction per user per post
);

CREATE INDEX idx_reactions_post_id ON reactions(post_id);
CREATE INDEX idx_reactions_user_id ON reactions(user_id);

-- =====================================================
-- COMMENTS TABLE
-- =====================================================
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_deleted BOOLEAN DEFAULT false, -- Soft delete for moderation
    deleted_by UUID REFERENCES users(id), -- Admin who deleted
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);

-- =====================================================
-- BOARD QUESTIONS TABLE (User-submitted questions)
-- =====================================================
CREATE TABLE board_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'answered', 'archived'
    admin_response TEXT,
    responded_by UUID REFERENCES users(id),
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_board_questions_user_id ON board_questions(user_id);
CREATE INDEX idx_board_questions_status ON board_questions(status);
CREATE INDEX idx_board_questions_created_at ON board_questions(created_at DESC);

-- =====================================================
-- MATERIALIZED VIEW: Post Stats (Performance Optimization)
-- =====================================================
CREATE MATERIALIZED VIEW post_stats AS
SELECT 
    p.id AS post_id,
    COUNT(DISTINCT r.id) AS reaction_count,
    COUNT(DISTINCT c.id) FILTER (WHERE c.is_deleted = false) AS comment_count,
    p.view_count
FROM posts p
LEFT JOIN reactions r ON p.id = r.post_id
LEFT JOIN comments c ON p.id = c.post_id
GROUP BY p.id, p.view_count;

CREATE UNIQUE INDEX idx_post_stats_post_id ON post_stats(post_id);

-- Refresh function for materialized view
CREATE OR REPLACE FUNCTION refresh_post_stats()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY post_stats;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers to auto-refresh stats
CREATE TRIGGER trigger_refresh_post_stats_reactions
AFTER INSERT OR DELETE ON reactions
FOR EACH STATEMENT EXECUTE FUNCTION refresh_post_stats();

CREATE TRIGGER trigger_refresh_post_stats_comments
AFTER INSERT OR UPDATE ON comments
FOR EACH STATEMENT EXECUTE FUNCTION refresh_post_stats();

-- =====================================================
-- AUDIT LOG TABLE (Track Admin Actions)
-- =====================================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES users(id),
    action VARCHAR(50) NOT NULL, -- 'block_user', 'delete_comment', 'unblock_user'
    target_type VARCHAR(50), -- 'user', 'comment', 'post'
    target_id UUID,
    metadata JSONB, -- Additional context
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_admin_id ON audit_logs(admin_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- =====================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_board_questions_updated_at BEFORE UPDATE ON board_questions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
