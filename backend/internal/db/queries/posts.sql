-- name: GetFeed :many
SELECT 
    p.id, p.author_id, p.title, p.content, p.image_url, 
    p.published, p.view_count, p.created_at, p.updated_at,
    u.id as author_id, u.display_name as author_name, u.avatar_url as author_avatar,
    COALESCE(ps.reaction_count, 0) as reaction_count,
    COALESCE(ps.comment_count, 0) as comment_count,
    CASE WHEN r.id IS NOT NULL THEN true ELSE false END as user_has_reacted
FROM posts p
JOIN users u ON p.author_id = u.id
LEFT JOIN post_stats ps ON p.id = ps.post_id
LEFT JOIN reactions r ON p.id = r.post_id AND r.user_id = sqlc.narg('viewer_user_id')
WHERE p.published = true
ORDER BY p.created_at DESC
LIMIT $1 OFFSET $2;

-- name: CountPublishedPosts :one
SELECT COUNT(*) FROM posts WHERE published = true;

-- name: GetPostByID :one
SELECT 
    p.id, p.author_id, p.title, p.content, p.image_url, 
    p.published, p.view_count, p.created_at, p.updated_at,
    u.id as author_id, u.display_name as author_name, u.avatar_url as author_avatar,
    COALESCE(ps.reaction_count, 0) as reaction_count,
    COALESCE(ps.comment_count, 0) as comment_count,
    CASE WHEN r.id IS NOT NULL THEN true ELSE false END as user_has_reacted
FROM posts p
JOIN users u ON p.author_id = u.id
LEFT JOIN post_stats ps ON p.id = ps.post_id
LEFT JOIN reactions r ON p.id = r.post_id AND r.user_id = sqlc.narg('viewer_user_id')
WHERE p.id = $1;

-- name: CreatePost :one
INSERT INTO posts (
    author_id, title, content, image_url, published
) VALUES (
    $1, $2, $3, $4, $5
)
RETURNING *;

-- name: UpdatePost :one
UPDATE posts
SET 
    title = $2,
    content = $3,
    image_url = $4,
    published = $5,
    updated_at = NOW()
WHERE id = $1
RETURNING *;

-- name: DeletePost :exec
DELETE FROM posts WHERE id = $1;

-- name: IncrementViewCount :exec
UPDATE posts
SET view_count = view_count + 1
WHERE id = $1;
