-- name: CreateAuditLog :one
INSERT INTO audit_logs (
    admin_id, action, target_type, target_id, metadata
) VALUES (
    $1, $2, $3, $4, $5
)
RETURNING *;

-- name: GetAuditLogs :many
SELECT * FROM audit_logs
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;
