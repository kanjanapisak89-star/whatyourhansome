-- =====================================================
-- Rollback Content-to-Customer Platform Schema
-- =====================================================

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_refresh_post_stats_comments ON comments;
DROP TRIGGER IF EXISTS trigger_refresh_post_stats_reactions ON reactions;
DROP TRIGGER IF EXISTS update_board_questions_updated_at ON board_questions;
DROP TRIGGER IF EXISTS update_comments_updated_at ON comments;
DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
DROP TRIGGER IF EXISTS update_users_updated_at ON users;

-- Drop functions
DROP FUNCTION IF EXISTS refresh_post_stats();
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop materialized view
DROP MATERIALIZED VIEW IF EXISTS post_stats;

-- Drop tables (reverse order of creation)
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS board_questions;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS reactions;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

-- Drop enums
DROP TYPE IF EXISTS content_type;
DROP TYPE IF EXISTS user_status;
DROP TYPE IF EXISTS user_role;
