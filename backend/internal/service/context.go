package service

import (
	"context"
)

type contextKey string

const (
	userIDKey     contextKey = "user_id"
	firebaseUIDKey contextKey = "firebase_uid"
	userRoleKey   contextKey = "user_role"
)

// GetUserIDFromContext retrieves the authenticated user's ID from context
func GetUserIDFromContext(ctx context.Context) string {
	if userID, ok := ctx.Value(userIDKey).(string); ok {
		return userID
	}
	return ""
}

// GetFirebaseUIDFromContext retrieves the Firebase UID from context
func GetFirebaseUIDFromContext(ctx context.Context) string {
	if uid, ok := ctx.Value(firebaseUIDKey).(string); ok {
		return uid
	}
	return ""
}

// GetUserRoleFromContext retrieves the user's role from context
func GetUserRoleFromContext(ctx context.Context) string {
	if role, ok := ctx.Value(userRoleKey).(string); ok {
		return role
	}
	return ""
}

// SetUserIDInContext adds user ID to context
func SetUserIDInContext(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, userIDKey, userID)
}

// SetFirebaseUIDInContext adds Firebase UID to context
func SetFirebaseUIDInContext(ctx context.Context, uid string) context.Context {
	return context.WithValue(ctx, firebaseUIDKey, uid)
}

// SetUserRoleInContext adds user role to context
func SetUserRoleInContext(ctx context.Context, role string) context.Context {
	return context.WithValue(ctx, userRoleKey, role)
}
