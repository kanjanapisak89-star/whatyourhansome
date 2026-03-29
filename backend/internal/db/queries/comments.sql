-- name: GetCommentsByPostID :many
SELECT 
    c.id, c.post_id, c.user_id, c.content, c.is_deleted,
    c.created_at, c.updated_at,
    u.id as author_id, u.display_name as author_name, u.avatar_url as author_avatar
FROM comments c
JOIN users u ON c.user_id = u.id
WHERE c.post_id = $1 AND c.is_deleted = false
ORDER BY c.created_at DESC
LIMIT $2 OFFSET $3;

-- name: CountCommentsByPostID :one
SELECT COUNT(*) FROM comments
WHERE post_id = $1 AND is_deleted = false;

-- name: CreateComment :one
INSERT INTO comments (post_id, user_id, content)
VALUES ($1, $2, $3)
RETURNING *;

-- name: SoftDeleteComment :exec
UPDATE comments
SET 
    is_deleted = true,
    deleted_by = $2,
    deleted_at = NOW(),
    updated_at = NOW()
WHERE id = $1;
