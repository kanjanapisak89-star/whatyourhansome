package service

import (
	"context"
	"fmt"
	"strings"
	"time"

	"connectrpc.com/connect"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	loftv1 "github.com/medlab/loft/backend/gen/proto/loft/v1"
	"github.com/medlab/loft/backend/internal/auth"
)

// --- MemberService ---

func (s *Loft) TogglePostReaction(ctx context.Context, req *connect.Request[loftv1.TogglePostReactionRequest]) (*connect.Response[loftv1.TogglePostReactionResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	u := auth.AppUserFromContext(ctx)
	if u == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("user context missing"))
	}
	if rt := req.Msg.GetReactionType(); rt != loftv1.ReactionType_REACTION_TYPE_HEART &&
		rt != loftv1.ReactionType_REACTION_TYPE_UNSPECIFIED {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("reaction_type"))
	}
	postID, err := uuid.Parse(strings.TrimSpace(req.Msg.GetPostId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("post_id"))
	}

	tx, err := s.pool().Begin(ctx)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	defer tx.Rollback(ctx)

	var n int
	if err := tx.QueryRow(ctx, `
SELECT COUNT(*) FROM post_reactions WHERE post_id = $1 AND user_id = $2 AND reaction_type = 'heart'`,
		postID, u.ID).Scan(&n); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	reacted := false
	if n > 0 {
		if _, err := tx.Exec(ctx, `
DELETE FROM post_reactions WHERE post_id = $1 AND user_id = $2 AND reaction_type = 'heart'`,
			postID, u.ID); err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
	} else {
		if _, err := tx.Exec(ctx, `
INSERT INTO post_reactions (post_id, user_id, reaction_type) VALUES ($1, $2, 'heart')`,
			postID, u.ID); err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
		reacted = true
	}
	var likes int32
	if err := tx.QueryRow(ctx, `SELECT like_count FROM posts WHERE id = $1 AND deleted_at IS NULL`, postID).Scan(&likes); err != nil {
		if err == pgx.ErrNoRows {
			return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("post"))
		}
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&loftv1.TogglePostReactionResponse{Reacted: reacted, LikeCount: likes}), nil
}

func (s *Loft) CreatePostComment(ctx context.Context, req *connect.Request[loftv1.CreatePostCommentRequest]) (*connect.Response[loftv1.CreatePostCommentResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	u := auth.AppUserFromContext(ctx)
	if u == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("user context missing"))
	}
	body := strings.TrimSpace(req.Msg.GetBody())
	if body == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("body"))
	}
	postID, err := uuid.Parse(strings.TrimSpace(req.Msg.GetPostId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("post_id"))
	}
	var cid uuid.UUID
	var created, updated time.Time
	if err := s.pool().QueryRow(ctx, `
INSERT INTO comments (post_id, author_user_id, body) VALUES ($1, $2, $3)
RETURNING id, created_at, updated_at`, postID, u.ID, body).Scan(&cid, &created, &updated); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	av := strPtrOrNil(u.AvatarURL)
	c := &loftv1.Comment{
		Id: cid.String(), PostId: postID.String(),
		Author:        userPublic(u.ID, u.DisplayName, nil, av),
		Body:          body,
		CreatedAtUnix: unix(created),
		UpdatedAtUnix: unix(updated),
	}
	return connect.NewResponse(&loftv1.CreatePostCommentResponse{Comment: c}), nil
}

func strPtrOrNil(s string) *string {
	if strings.TrimSpace(s) == "" {
		return nil
	}
	return &s
}

func (s *Loft) RecordPostShare(ctx context.Context, req *connect.Request[loftv1.RecordPostShareRequest]) (*connect.Response[loftv1.RecordPostShareResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	u := auth.AppUserFromContext(ctx)
	if u == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("user context missing"))
	}
	postID, err := uuid.Parse(strings.TrimSpace(req.Msg.GetPostId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("post_id"))
	}
	ch := strings.TrimSpace(req.Msg.GetChannel())
	if _, err := s.pool().Exec(ctx, `
INSERT INTO post_share_events (post_id, user_id, channel) VALUES ($1, $2, NULLIF($3, ''))`,
		postID, u.ID, ch); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	var shares int32
	if err := s.pool().QueryRow(ctx, `SELECT share_count FROM posts WHERE id = $1`, postID).Scan(&shares); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&loftv1.RecordPostShareResponse{ShareCount: shares}), nil
}

func (s *Loft) CreateBoardThread(ctx context.Context, req *connect.Request[loftv1.CreateBoardThreadRequest]) (*connect.Response[loftv1.CreateBoardThreadResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	u := auth.AppUserFromContext(ctx)
	if u == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("user context missing"))
	}
	boardID, err := uuid.Parse(strings.TrimSpace(req.Msg.GetBoardId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("board_id"))
	}
	title := strings.TrimSpace(req.Msg.GetTitle())
	body := strings.TrimSpace(req.Msg.GetBody())
	if title == "" || body == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("title and body required"))
	}
	var tid uuid.UUID
	var created, updated time.Time
	if err := s.pool().QueryRow(ctx, `
INSERT INTO board_threads (board_id, author_user_id, title, body) VALUES ($1, $2, $3, $4)
RETURNING id, created_at, updated_at`, boardID, u.ID, title, body).Scan(&tid, &created, &updated); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	th := &loftv1.BoardThread{
		Id: tid.String(), BoardId: boardID.String(),
		Author:        userPublic(u.ID, u.DisplayName, nil, strPtrOrNil(u.AvatarURL)),
		Title:         title,
		Body:          body,
		Status:        loftv1.BoardThreadStatus_BOARD_THREAD_STATUS_OPEN,
		CreatedAtUnix: unix(created),
		UpdatedAtUnix: unix(updated),
	}
	return connect.NewResponse(&loftv1.CreateBoardThreadResponse{Thread: th}), nil
}

// --- AdminService ---

func (s *Loft) ModerateDeleteComment(ctx context.Context, req *connect.Request[loftv1.ModerateDeleteCommentRequest]) (*connect.Response[loftv1.ModerateDeleteCommentResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	admin := auth.AppUserFromContext(ctx)
	if admin == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("user context missing"))
	}
	cid, err := uuid.Parse(strings.TrimSpace(req.Msg.GetCommentId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("comment_id"))
	}
	reason := strings.TrimSpace(req.Msg.GetReason())
	if reason == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("reason"))
	}
	tag, err := s.pool().Exec(ctx, `
UPDATE comments SET deleted_at = now(), deleted_by_user_id = $1, delete_reason = $2, updated_at = now()
WHERE id = $3 AND deleted_at IS NULL`, admin.ID, reason, cid)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	if tag.RowsAffected() == 0 {
		return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("comment"))
	}
	return connect.NewResponse(&loftv1.ModerateDeleteCommentResponse{}), nil
}

func (s *Loft) SetUserBlocked(ctx context.Context, req *connect.Request[loftv1.SetUserBlockedRequest]) (*connect.Response[loftv1.SetUserBlockedResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	admin := auth.AppUserFromContext(ctx)
	if admin == nil {
		return nil, connect.NewError(connect.CodeUnauthenticated, fmt.Errorf("user context missing"))
	}
	target, err := uuid.Parse(strings.TrimSpace(req.Msg.GetUserId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("user_id"))
	}
	if target == admin.ID {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("cannot block self"))
	}
	blocked := req.Msg.GetBlocked()
	reason := strings.TrimSpace(req.Msg.GetReason())
	if blocked && reason == "" {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("reason required when blocking"))
	}
	ct, err := s.pool().Exec(ctx, `
UPDATE users SET
  blocked_at = CASE WHEN $2 THEN now() ELSE NULL END,
  blocked_reason = CASE WHEN $2 THEN $3 ELSE NULL END,
  updated_at = now()
WHERE id = $1`, target, blocked, reason)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	if ct.RowsAffected() == 0 {
		return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("user"))
	}
	return connect.NewResponse(&loftv1.SetUserBlockedResponse{}), nil
}
