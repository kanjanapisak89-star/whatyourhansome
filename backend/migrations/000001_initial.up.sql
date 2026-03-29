-- Loft initial schema: users, categories, posts, reactions, comments, shares, boards, content_blocks
-- PostgreSQL 14+ (uses gen_random_uuid from pgcrypto)

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE user_role AS ENUM ('member', 'admin', 'owner');
CREATE TYPE auth_provider AS ENUM ('google', 'facebook');
CREATE TYPE publish_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE board_thread_status AS ENUM ('open', 'answered', 'locked', 'archived');
CREATE TYPE reaction_type AS ENUM ('heart');

CREATE TABLE users (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid      TEXT NOT NULL UNIQUE,
  email             TEXT,
  display_name      TEXT NOT NULL,
  headline          TEXT,
  avatar_url        TEXT,
  primary_provider  auth_provider NOT NULL,
  role              user_role NOT NULL DEFAULT 'member',
  blocked_at        TIMESTAMPTZ,
  blocked_reason    TEXT,
  last_login_at     TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT users_blocked_requires_reason CHECK (blocked_at IS NULL OR blocked_reason IS NOT NULL)
);

CREATE INDEX idx_users_role ON users (role);
CREATE INDEX idx_users_blocked ON users (blocked_at) WHERE blocked_at IS NOT NULL;

CREATE TABLE categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        TEXT NOT NULL UNIQUE,
  label       TEXT NOT NULL,
  sort_order  INT NOT NULL DEFAULT 0,
  icon_key    TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE boards (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        TEXT NOT NULL UNIQUE,
  title       TEXT NOT NULL,
  description TEXT,
  sort_order  INT NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE posts (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_user_id     UUID REFERENCES users (id) ON DELETE SET NULL,
  category_id        UUID NOT NULL REFERENCES categories (id),
  status             publish_status NOT NULL DEFAULT 'draft',
  title              TEXT NOT NULL,
  excerpt            TEXT NOT NULL,
  body               TEXT,
  hero_image_url     TEXT NOT NULL,
  published_at       TIMESTAMPTZ,
  like_count         INT NOT NULL DEFAULT 0 CHECK (like_count >= 0),
  comment_count      INT NOT NULL DEFAULT 0 CHECK (comment_count >= 0),
  share_count        INT NOT NULL DEFAULT 0 CHECK (share_count >= 0),
  search_vector      tsvector,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at         TIMESTAMPTZ,
  CONSTRAINT posts_published_requires_time CHECK (status <> 'published' OR published_at IS NOT NULL)
);

CREATE INDEX idx_posts_feed ON posts (category_id, published_at DESC) WHERE status = 'published' AND deleted_at IS NULL;
CREATE INDEX idx_posts_published ON posts (published_at DESC) WHERE status = 'published' AND deleted_at IS NULL;
CREATE INDEX idx_posts_search ON posts USING GIN (search_vector) WHERE deleted_at IS NULL;

CREATE TABLE post_reactions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id       UUID NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  reaction_type reaction_type NOT NULL DEFAULT 'heart',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (post_id, user_id, reaction_type)
);

CREATE INDEX idx_post_reactions_post ON post_reactions (post_id);
CREATE INDEX idx_post_reactions_user ON post_reactions (user_id);

CREATE TABLE comments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id             UUID NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
  author_user_id      UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  body                TEXT NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at          TIMESTAMPTZ,
  deleted_by_user_id  UUID REFERENCES users (id) ON DELETE SET NULL,
  delete_reason       TEXT
);

CREATE INDEX idx_comments_post ON comments (post_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_comments_author ON comments (author_user_id);

CREATE TABLE post_share_events (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
  user_id    UUID REFERENCES users (id) ON DELETE SET NULL,
  channel    TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_share_events_post ON post_share_events (post_id);

CREATE TABLE board_threads (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id         UUID NOT NULL REFERENCES boards (id) ON DELETE CASCADE,
  author_user_id   UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  body             TEXT NOT NULL,
  status           board_thread_status NOT NULL DEFAULT 'open',
  answer_post_id   UUID REFERENCES posts (id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  locked_reason    TEXT
);

CREATE INDEX idx_board_threads_board ON board_threads (board_id, created_at DESC);
CREATE INDEX idx_board_threads_author ON board_threads (author_user_id);

CREATE TABLE board_thread_comments (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id          UUID NOT NULL REFERENCES board_threads (id) ON DELETE CASCADE,
  author_user_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  body               TEXT NOT NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at         TIMESTAMPTZ,
  deleted_by_user_id UUID REFERENCES users (id) ON DELETE SET NULL,
  delete_reason      TEXT
);

CREATE INDEX idx_board_thread_comments_thread ON board_thread_comments (thread_id) WHERE deleted_at IS NULL;

CREATE TABLE content_blocks (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key        TEXT NOT NULL,
  locale     TEXT NOT NULL DEFAULT 'en',
  value      JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (key, locale)
);

-- Keep search_vector in sync for title, excerpt, body
CREATE OR REPLACE FUNCTION posts_search_vector_update()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A')
    || setweight(to_tsvector('english', coalesce(NEW.excerpt, '')), 'B')
    || setweight(to_tsvector('english', coalesce(NEW.body, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_posts_search_vector
  BEFORE INSERT OR UPDATE OF title, excerpt, body ON posts
  FOR EACH ROW
  EXECUTE PROCEDURE posts_search_vector_update();

-- Denormalized like_count
CREATE OR REPLACE FUNCTION post_reactions_adjust_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.reaction_type = 'heart' THEN
    UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' AND OLD.reaction_type = 'heart' THEN
    UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_post_reactions_like_count_ins
  AFTER INSERT ON post_reactions
  FOR EACH ROW
  EXECUTE PROCEDURE post_reactions_adjust_like_count();

CREATE TRIGGER trg_post_reactions_like_count_del
  AFTER DELETE ON post_reactions
  FOR EACH ROW
  EXECUTE PROCEDURE post_reactions_adjust_like_count();

-- Denormalized comment_count (respects soft delete)
CREATE OR REPLACE FUNCTION comments_adjust_post_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.deleted_at IS NULL THEN
      UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
      UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = NEW.post_id;
    ELSIF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
      UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.deleted_at IS NULL THEN
      UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
    END IF;
    RETURN OLD;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comments_post_count_ins
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE PROCEDURE comments_adjust_post_count();

CREATE TRIGGER trg_comments_post_count_upd
  AFTER UPDATE ON comments
  FOR EACH ROW
  EXECUTE PROCEDURE comments_adjust_post_count();

CREATE TRIGGER trg_comments_post_count_del
  AFTER DELETE ON comments
  FOR EACH ROW
  EXECUTE PROCEDURE comments_adjust_post_count();

-- Denormalized share_count
CREATE OR REPLACE FUNCTION post_share_events_adjust_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET share_count = share_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET share_count = GREATEST(share_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_post_share_events_count_ins
  AFTER INSERT ON post_share_events
  FOR EACH ROW
  EXECUTE PROCEDURE post_share_events_adjust_count();

CREATE TRIGGER trg_post_share_events_count_del
  AFTER DELETE ON post_share_events
  FOR EACH ROW
  EXECUTE PROCEDURE post_share_events_adjust_count();
