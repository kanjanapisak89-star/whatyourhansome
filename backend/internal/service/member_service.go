package service

import (
	"context"
	"database/sql"

	"connectrpc.com/connect"
	loftv1 "github.com/medlab/loft/backend/gen/proto/loft/v1"
)

type MemberService struct {
	db *sql.DB
}

func NewMemberService(db *sql.DB) *MemberService {
	return &MemberService{db: db}
}

// ToggleReaction adds or removes a reaction (like) on a post
func (s *MemberService) ToggleReaction(
	ctx context.Context,
	req *connect.Request[loftv1.ToggleReactionRequest],
) (*connect.Response[loftv1.ToggleReactionResponse], error) {
	userID := GetUserIDFromContext(ctx)
	if userID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	// 1. Check if reaction exists
	// 2. If exists, delete it (unlike)
	// 3. If not exists, create it (like)
	// 4. Get new count
	
	return connect.NewResponse(&loftv1.ToggleReactionResponse{
		IsReacted: true,
		NewCount:  20,
	}), nil
}

// CreateComment adds a new comment to a post
func (s *MemberService) CreateComment(
	ctx context.Context,
	req *connect.Request[loftv1.CreateCommentRequest],
) (*connect.Response[loftv1.CreateCommentResponse], error) {
	userID := GetUserIDFromContext(ctx)
	if userID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	comment := &loftv1.Comment{
		Id:      "new-comment-id",
		PostId:  req.Msg.PostId,
		UserId:  userID,
		Content: req.Msg.Content,
		Author: &loftv1.UserPublic{
			Id:          userID,
			DisplayName: "Current User",
			AvatarUrl:   "",
		},
		CreatedAtUnix: 1234567890,
	}
	
	return connect.NewResponse(&loftv1.CreateCommentResponse{
		Comment: comment,
	}), nil
}

// CreateBoardQuestion submits a new question to the board
func (s *MemberService) CreateBoardQuestion(
	ctx context.Context,
	req *connect.Request[loftv1.CreateBoardQuestionRequest],
) (*connect.Response[loftv1.CreateBoardQuestionResponse], error) {
	userID := GetUserIDFromContext(ctx)
	if userID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	question := &loftv1.BoardQuestion{
		Id:      "new-question-id",
		UserId:  userID,
		Title:   req.Msg.Title,
		Content: req.Msg.Content,
		Status:  loftv1.QuestionStatus_QUESTION_STATUS_PENDING,
		Author: &loftv1.UserPublic{
			Id:          userID,
			DisplayName: "Current User",
			AvatarUrl:   "",
		},
		CreatedAtUnix: 1234567890,
	}
	
	return connect.NewResponse(&loftv1.CreateBoardQuestionResponse{
		Question: question,
	}), nil
}

// GetMyQuestions returns the current user's board questions
func (s *MemberService) GetMyQuestions(
	ctx context.Context,
	req *connect.Request[loftv1.GetMyQuestionsRequest],
) (*connect.Response[loftv1.GetMyQuestionsResponse], error) {
	userID := GetUserIDFromContext(ctx)
	if userID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	questions := []*loftv1.BoardQuestion{}
	
	return connect.NewResponse(&loftv1.GetMyQuestionsResponse{
		Questions:  questions,
		TotalCount: 0,
		HasMore:    false,
	}), nil
}

// GetCurrentUser returns the authenticated user's profile
func (s *MemberService) GetCurrentUser(
	ctx context.Context,
	req *connect.Request[loftv1.GetCurrentUserRequest],
) (*connect.Response[loftv1.GetCurrentUserResponse], error) {
	userID := GetUserIDFromContext(ctx)
	if userID == "" {
		return nil, connect.NewError(connect.CodeUnauthenticated, nil)
	}
	
	// TODO: Implement with sqlc
	user := &loftv1.User{
		Id:          userID,
		DisplayName: "Current User",
		Email:       "user@example.com",
		Role:        loftv1.UserRole_USER_ROLE_MEMBER,
		Status:      loftv1.UserStatus_USER_STATUS_ACTIVE,
	}
	
	return connect.NewResponse(&loftv1.GetCurrentUserResponse{
		User: user,
	}), nil
}
