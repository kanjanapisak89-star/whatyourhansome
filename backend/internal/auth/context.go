package auth

import (
	"context"

	"github.com/google/uuid"
)

type ctxKey int

const (
	keyFirebaseUID ctxKey = iota + 1
	keyAppUser
)

// AppUser is the database-backed user after Firebase verification and sync.
type AppUser struct {
	ID              uuid.UUID
	FirebaseUID     string
	Email           string
	DisplayName     string
	AvatarURL       string
	PrimaryProvider string // "google" | "facebook"
	Role            string // member | admin | owner
	BlockedAt       *int64 // unix seconds if blocked
	BlockedReason   string
}

func (u *AppUser) IsBlocked() bool {
	return u != nil && u.BlockedAt != nil
}

func (u *AppUser) IsAdmin() bool {
	if u == nil {
		return false
	}
	return u.Role == "admin" || u.Role == "owner"
}

// WithAppUser stores the synced app user in context (for handlers).
func WithAppUser(ctx context.Context, u *AppUser) context.Context {
	return context.WithValue(ctx, keyAppUser, u)
}

// AppUserFromContext returns the synced user, or nil if absent.
func AppUserFromContext(ctx context.Context) *AppUser {
	v, _ := ctx.Value(keyAppUser).(*AppUser)
	return v
}

// WithFirebaseUID stores the raw Firebase uid (for diagnostics).
func WithFirebaseUID(ctx context.Context, uid string) context.Context {
	return context.WithValue(ctx, keyFirebaseUID, uid)
}

func FirebaseUIDFromContext(ctx context.Context) string {
	v, _ := ctx.Value(keyFirebaseUID).(string)
	return v
}
