-- name: GetUserByFirebaseUID :one
SELECT * FROM users
WHERE firebase_uid = $1 LIMIT 1;

-- name: GetUserByID :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: UpsertUser :one
INSERT INTO users (
    firebase_uid,
    email,
    display_name,
    avatar_url,
    provider,
    last_login_at
) VALUES (
    $1, $2, $3, $4, $5, NOW()
)
ON CONFLICT (firebase_uid)
DO UPDATE SET
    email = EXCLUDED.email,
    display_name = EXCLUDED.display_name,
    avatar_url = EXCLUDED.avatar_url,
    last_login_at = NOW(),
    updated_at = NOW()
RETURNING *;

-- name: BlockUser :exec
UPDATE users
SET status = 'blocked', updated_at = NOW()
WHERE id = $1;

-- name: UnblockUser :exec
UPDATE users
SET status = 'active', updated_at = NOW()
WHERE id = $1;
