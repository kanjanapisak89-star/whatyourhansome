-- name: GetBoardQuestionsByUserID :many
SELECT 
    bq.id, bq.user_id, bq.title, bq.content, bq.status,
    bq.admin_response, bq.responded_by, bq.responded_at,
    bq.created_at, bq.updated_at,
    u.id as author_id, u.display_name as author_name, u.avatar_url as author_avatar
FROM board_questions bq
JOIN users u ON bq.user_id = u.id
WHERE bq.user_id = $1
ORDER BY bq.created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetBoardQuestionsByStatus :many
SELECT 
    bq.id, bq.user_id, bq.title, bq.content, bq.status,
    bq.admin_response, bq.responded_by, bq.responded_at,
    bq.created_at, bq.updated_at,
    u.id as author_id, u.display_name as author_name, u.avatar_url as author_avatar
FROM board_questions bq
JOIN users u ON bq.user_id = u.id
WHERE bq.status = $1
ORDER BY bq.created_at DESC
LIMIT $2 OFFSET $3;

-- name: CountBoardQuestionsByUserID :one
SELECT COUNT(*) FROM board_questions
WHERE user_id = $1;

-- name: CountBoardQuestionsByStatus :one
SELECT COUNT(*) FROM board_questions
WHERE status = $1;

-- name: CreateBoardQuestion :one
INSERT INTO board_questions (user_id, title, content)
VALUES ($1, $2, $3)
RETURNING *;

-- name: RespondToBoardQuestion :one
UPDATE board_questions
SET 
    admin_response = $2,
    status = $3,
    responded_by = $4,
    responded_at = NOW(),
    updated_at = NOW()
WHERE id = $1
RETURNING *;
