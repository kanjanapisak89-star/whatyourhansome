package service

import (
	"context"
	"database/sql"

	"connectrpc.com/connect"
	loftv1 "github.com/medlab/loft/backend/gen/proto/loft/v1"
)

type AuthService struct {
	db *sql.DB
}

func NewAuthService(db *sql.DB) *AuthService {
	return &AuthService{db: db}
}

// SyncUser creates or updates a user from Firebase Auth data
func (s *AuthService) SyncUser(
	ctx context.Context,
	req *connect.Request[loftv1.SyncUserRequest],
) (*connect.Response[loftv1.SyncUserResponse], error) {
	// TODO: Implement with sqlc UpsertUser
	// This is called after Firebase Auth succeeds on the client
	
	user := &loftv1.User{
		Id:            "user-id",
		FirebaseUid:   req.Msg.FirebaseUid,
		Email:         req.Msg.Email,
		DisplayName:   req.Msg.DisplayName,
		AvatarUrl:     req.Msg.AvatarUrl,
		Provider:      req.Msg.Provider,
		Role:          loftv1.UserRole_USER_ROLE_MEMBER,
		Status:        loftv1.UserStatus_USER_STATUS_ACTIVE,
		CreatedAtUnix: 1234567890,
	}
	
	return connect.NewResponse(&loftv1.SyncUserResponse{
		User: user,
	}), nil
}
