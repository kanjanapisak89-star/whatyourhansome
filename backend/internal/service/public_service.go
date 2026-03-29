package service

import (
	"context"
	"database/sql"

	"connectrpc.com/connect"
	loftv1 "github.com/medlab/loft/backend/gen/proto/loft/v1"
)

type PublicService struct {
	db *sql.DB
}

func NewPublicService(db *sql.DB) *PublicService {
	return &PublicService{db: db}
}

// GetFeed returns paginated list of published posts
func (s *PublicService) GetFeed(
	ctx context.Context,
	req *connect.Request[loftv1.GetFeedRequest],
) (*connect.Response[loftv1.GetFeedResponse], error) {
	pageSize := req.Msg.PageSize
	if pageSize == 0 || pageSize > 50 {
		pageSize = 20
	}
	
	page := req.Msg.Page
	if page < 1 {
		page = 1
	}
	
	offset := (page - 1) * pageSize
	
	// Get viewer user ID from context (optional for guests)
	viewerUserID := GetUserIDFromContext(ctx)
	
	// TODO: Query posts with sqlc generated code
	// For now, return mock data
	posts := []*loftv1.Post{
		{
			Id:       "post-1",
			AuthorId: "user-1",
			Title:    "The Obsidian Shift: Why physical borders are becoming digital posts.",
			Content:  "We are entering an era where the architecture of our reality...",
			ImageUrl: "https://example.com/image1.jpg",
			Published: true,
			CreatedAtUnix: 1234567890,
			Author: &loftv1.UserPublic{
				Id:          "user-1",
				DisplayName: "Marcus Thorne",
				AvatarUrl:   "https://example.com/avatar1.jpg",
			},
			Stats: &loftv1.PostStats{
				ReactionCount: 19,
				CommentCount:  84,
				ViewCount:     1250,
			},
			UserHasReacted: false,
		},
	}
	
	totalCount := int32(len(posts))
	hasMore := totalCount > pageSize
	
	return connect.NewResponse(&loftv1.GetFeedResponse{
		Posts:      posts,
		TotalCount: totalCount,
		HasMore:    hasMore,
	}), nil
}

// GetPost returns a single post by ID
func (s *PublicService) GetPost(
	ctx context.Context,
	req *connect.Request[loftv1.GetPostRequest],
) (*connect.Response[loftv1.GetPostResponse], error) {
	// TODO: Implement with sqlc
	post := &loftv1.Post{
		Id:       req.Msg.PostId,
		AuthorId: "user-1",
		Title:    "The Obsidian Shift",
		Content:  "Full content here...",
		ImageUrl: "https://example.com/image1.jpg",
		Author: &loftv1.UserPublic{
			Id:          "user-1",
			DisplayName: "Marcus Thorne",
			AvatarUrl:   "https://example.com/avatar1.jpg",
		},
		Stats: &loftv1.PostStats{
			ReactionCount: 19,
			CommentCount:  84,
			ViewCount:     1250,
		},
	}
	
	return connect.NewResponse(&loftv1.GetPostResponse{
		Post: post,
	}), nil
}

// GetComments returns paginated comments for a post
func (s *PublicService) GetComments(
	ctx context.Context,
	req *connect.Request[loftv1.GetCommentsRequest],
) (*connect.Response[loftv1.GetCommentsResponse], error) {
	pageSize := req.Msg.PageSize
	if pageSize == 0 || pageSize > 100 {
		pageSize = 20
	}
	
	// TODO: Implement with sqlc
	comments := []*loftv1.Comment{
		{
			Id:      "comment-1",
			PostId:  req.Msg.PostId,
			UserId:  "user-2",
			Content: "Great insights!",
			Author: &loftv1.UserPublic{
				Id:          "user-2",
				DisplayName: "Sarah Chen",
				AvatarUrl:   "https://example.com/avatar2.jpg",
			},
			CreatedAtUnix: 1234567890,
		},
	}
	
	return connect.NewResponse(&loftv1.GetCommentsResponse{
		Comments:   comments,
		TotalCount: int32(len(comments)),
		HasMore:    false,
	}), nil
}
