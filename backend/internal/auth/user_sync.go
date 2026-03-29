package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrUserBlocked = errors.New("user is blocked")

// UserSyncer loads or creates the app user row for a verified Firebase identity.
type UserSyncer struct {
	pool *pgxpool.Pool
}

func NewUserSyncer(pool *pgxpool.Pool) *UserSyncer {
	return &UserSyncer{pool: pool}
}

// SyncUser inserts or updates users on login and returns the app user including role and block state.
func (s *UserSyncer) SyncUser(ctx context.Context, v *VerifiedToken) (*AppUser, error) {
	if s.pool == nil {
		return nil, fmt.Errorf("user sync: database not configured")
	}
	display := strings.TrimSpace(v.DisplayName)
	if display == "" {
		display = strings.TrimSpace(v.Email)
	}
	if display == "" {
		display = "Member"
	}
	const q = `
INSERT INTO users (
  firebase_uid, email, display_name, avatar_url, primary_provider, last_login_at, updated_at
) VALUES (
  $1, NULLIF($2, ''), $3, NULLIF($4, ''), $5::auth_provider, now(), now()
)
ON CONFLICT (firebase_uid) DO UPDATE SET
  email = COALESCE(NULLIF(EXCLUDED.email, ''), users.email),
  display_name = EXCLUDED.display_name,
  avatar_url = COALESCE(NULLIF(EXCLUDED.avatar_url, ''), users.avatar_url),
  last_login_at = now(),
  updated_at = now()
RETURNING
  id, firebase_uid, email, display_name, avatar_url, primary_provider::text, role::text,
  blocked_at, blocked_reason;
`
	row := s.pool.QueryRow(ctx, q,
		v.UID,
		v.Email,
		display,
		v.PhotoURL,
		v.AuthProvider,
	)
	var (
		id        uuid.UUID
		fbUID     string
		email     *string
		dname     string
		avatar    *string
		provider  string
		role      string
		blockedAt *time.Time
		reason    *string
	)
	if err := row.Scan(
		&id, &fbUID, &email, &dname, &avatar, &provider, &role, &blockedAt, &reason,
	); err != nil {
		return nil, err
	}
	u := &AppUser{
		ID:              id,
		FirebaseUID:     fbUID,
		DisplayName:     dname,
		PrimaryProvider: provider,
		Role:            role,
	}
	if email != nil {
		u.Email = *email
	}
	if avatar != nil {
		u.AvatarURL = *avatar
	}
	if blockedAt != nil {
		sec := blockedAt.Unix()
		u.BlockedAt = &sec
	}
	if reason != nil {
		u.BlockedReason = *reason
	}
	if u.IsBlocked() {
		return u, fmt.Errorf("%w", ErrUserBlocked)
	}
	return u, nil
}

// LookupUserByFirebaseUID reads user without mutating (optional helper).
func (s *UserSyncer) LookupUserByFirebaseUID(ctx context.Context, firebaseUID string) (*AppUser, error) {
	const q = `
SELECT id, firebase_uid, email, display_name, avatar_url, primary_provider::text, role::text,
       blocked_at, blocked_reason
FROM users WHERE firebase_uid = $1`
	row := s.pool.QueryRow(ctx, q, firebaseUID)
	var (
		id        uuid.UUID
		fb        string
		email     *string
		dname     string
		avatar    *string
		provider  string
		role      string
		blockedAt *time.Time
		reason    *string
	)
	if err := row.Scan(&id, &fb, &email, &dname, &avatar, &provider, &role, &blockedAt, &reason); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	u := &AppUser{
		ID:              id,
		FirebaseUID:     fb,
		DisplayName:     dname,
		PrimaryProvider: provider,
		Role:            role,
	}
	if email != nil {
		u.Email = *email
	}
	if avatar != nil {
		u.AvatarURL = *avatar
	}
	if blockedAt != nil {
		sec := blockedAt.Unix()
		u.BlockedAt = &sec
	}
	if reason != nil {
		u.BlockedReason = *reason
	}
	return u, nil
}
