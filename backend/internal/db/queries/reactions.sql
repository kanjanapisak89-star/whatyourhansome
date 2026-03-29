-- name: GetReaction :one
SELECT * FROM reactions
WHERE user_id = $1 AND post_id = $2
LIMIT 1;

-- name: CreateReaction :one
INSERT INTO reactions (user_id, post_id)
VALUES ($1, $2)
ON CONFLICT (user_id, post_id) DO NOTHING
RETURNING *;

-- name: DeleteReaction :exec
DELETE FROM reactions
WHERE user_id = $1 AND post_id = $2;

-- name: GetReactionCount :one
SELECT COUNT(*) FROM reactions
WHERE post_id = $1;
