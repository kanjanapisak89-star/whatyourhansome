-- Reverse initial schema (drop triggers and functions before tables/types)

DROP TRIGGER IF EXISTS trg_post_share_events_count_del ON post_share_events;
DROP TRIGGER IF EXISTS trg_post_share_events_count_ins ON post_share_events;
DROP FUNCTION IF EXISTS post_share_events_adjust_count();

DROP TRIGGER IF EXISTS trg_comments_post_count_del ON comments;
DROP TRIGGER IF EXISTS trg_comments_post_count_upd ON comments;
DROP TRIGGER IF EXISTS trg_comments_post_count_ins ON comments;
DROP FUNCTION IF EXISTS comments_adjust_post_count();

DROP TRIGGER IF EXISTS trg_post_reactions_like_count_del ON post_reactions;
DROP TRIGGER IF EXISTS trg_post_reactions_like_count_ins ON post_reactions;
DROP FUNCTION IF EXISTS post_reactions_adjust_like_count();

DROP TRIGGER IF EXISTS trg_posts_search_vector ON posts;
DROP FUNCTION IF EXISTS posts_search_vector_update();

DROP TABLE IF EXISTS content_blocks;
DROP TABLE IF EXISTS board_thread_comments;
DROP TABLE IF EXISTS board_threads;
DROP TABLE IF EXISTS post_share_events;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS post_reactions;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS boards;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

DROP TYPE IF EXISTS reaction_type;
DROP TYPE IF EXISTS board_thread_status;
DROP TYPE IF EXISTS publish_status;
DROP TYPE IF EXISTS auth_provider;
DROP TYPE IF EXISTS user_role;
