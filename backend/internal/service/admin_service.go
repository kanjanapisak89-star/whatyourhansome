package service

import (
	"context"
	"database/sql"

	"connectrpc.com/connect"
	loftv1 "github.com/medlab/loft/backend/gen/proto/loft/v1"
)

type AdminService struct {
	db *sql.DB
}

func NewAdminService(db *sql.DB) *AdminService {
	return &AdminService{db: db}
}

// CreatePost creates a new content post (admin/owner only)
func (s *AdminService) CreatePost(
	ctx context.Context,
	req *connect.Request[loftv1.CreatePostRequest],
) (*connect.Response[loftv1.CreatePostResponse], error) {
	userID := GetUserIDFromContext(ctx)
	if userID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Check if user is admin/owner
	// TODO: Implement with sqlc
	
	post := &loftv1.Post{
		Id:        "new-post-id",
		AuthorId:  userID,
		Title:     req.Msg.Title,
		Content:   req.Msg.Content,
		ImageUrl:  req.Msg.ImageUrl,
		Published: req.Msg.Published,
		Stats: &loftv1.PostStats{
			ReactionCount: 0,
			CommentCount:  0,
			ViewCount:     0,
		},
		CreatedAtUnix: 1234567890,
	}
	
	return connect.NewResponse(&loftv1.CreatePostResponse{
		Post: post,
	}), nil
}

// UpdatePost updates an existing post
func (s *AdminService) UpdatePost(
	ctx context.Context,
	req *connect.Request[loftv1.UpdatePostRequest],
) (*connect.Response[loftv1.UpdatePostResponse], error) {
	userID := GetUserIDFromContext(ctx)
	if userID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	post := &loftv1.Post{
		Id:        req.Msg.PostId,
		Title:     req.Msg.Title,
		Content:   req.Msg.Content,
		ImageUrl:  req.Msg.ImageUrl,
		Published: req.Msg.Published,
	}
	
	return connect.NewResponse(&loftv1.UpdatePostResponse{
		Post: post,
	}), nil
}

// DeletePost removes a post
func (s *AdminService) DeletePost(
	ctx context.Context,
	req *connect.Request[loftv1.DeletePostRequest],
) (*connect.Response[loftv1.DeletePostResponse], error) {
	userID := GetUserIDFromContext(ctx)
	if userID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	return connect.NewResponse(&loftv1.DeletePostResponse{
		Success: true,
	}), nil
}

// DeleteComment soft-deletes a comment (moderation)
func (s *AdminService) DeleteComment(
	ctx context.Context,
	req *connect.Request[loftv1.DeleteCommentRequest],
) (*connect.Response[loftv1.DeleteCommentResponse], error) {
	adminID := GetUserIDFromContext(ctx)
	if adminID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	// TODO: Create audit log
	
	return connect.NewResponse(&loftv1.DeleteCommentResponse{
		Success: true,
	}), nil
}

// BlockUser blocks a user account
func (s *AdminService) BlockUser(
	ctx context.Context,
	req *connect.Request[loftv1.BlockUserRequest],
) (*connect.Response[loftv1.BlockUserResponse], error) {
	adminID := GetUserIDFromContext(ctx)
	if adminID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	// TODO: Create audit log
	
	return connect.NewResponse(&loftv1.BlockUserResponse{
		Success: true,
	}), nil
}

// UnblockUser unblocks a user account
func (s *AdminService) UnblockUser(
	ctx context.Context,
	req *connect.Request[loftv1.UnblockUserRequest],
) (*connect.Response[loftv1.UnblockUserResponse], error) {
	adminID := GetUserIDFromContext(ctx)
	if adminID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	// TODO: Create audit log
	
	return connect.NewResponse(&loftv1.UnblockUserResponse{
		Success: true,
	}), nil
}

// GetBoardQuestions returns board questions filtered by status
func (s *AdminService) GetBoardQuestions(
	ctx context.Context,
	req *connect.Request[loftv1.GetBoardQuestionsRequest],
) (*connect.Response[loftv1.GetBoardQuestionsResponse], error) {
	adminID := GetUserIDFromContext(ctx)
	if adminID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	questions := []*loftv1.BoardQuestion{}
	
	return connect.NewResponse(&loftv1.GetBoardQuestionsResponse{
		Questions:  questions,
		TotalCount: 0,
		HasMore:    false,
	}), nil
}

// RespondToQuestion adds an admin response to a board question
func (s *AdminService) RespondToQuestion(
	ctx context.Context,
	req *connect.Request[loftv1.RespondToQuestionRequest],
) (*connect.Response[loftv1.RespondToQuestionResponse], error) {
	adminID := GetUserIDFromContext(ctx)
	if adminID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	question := &loftv1.BoardQuestion{
		Id:            req.Msg.QuestionId,
		AdminResponse: req.Msg.Response,
		Status:        req.Msg.NewStatus,
	}
	
	return connect.NewResponse(&loftv1.RespondToQuestionResponse{
		Question: question,
	}), nil
}
