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
)

func (s *Loft) GetPost(ctx context.Context, req *connect.Request[loftv1.GetPostRequest]) (*connect.Response[loftv1.GetPostResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	pid, err := uuid.Parse(strings.TrimSpace(req.Msg.GetPostId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("post_id"))
	}
	viewerStr := viewerIDString(ctx)
	row := s.pool().QueryRow(ctx, `
SELECT p.id, p.category_id, p.status::text, p.title, p.excerpt, p.body, p.hero_image_url,
  p.published_at, p.like_count, p.comment_count, p.share_count, p.created_at, p.updated_at,
  au.id, au.display_name, au.headline, au.avatar_url,
  EXISTS (
    SELECT 1 FROM post_reactions pr
    WHERE pr.post_id = p.id AND pr.reaction_type = 'heart'
      AND NULLIF($2::text, '') IS NOT NULL AND pr.user_id = $2::uuid
  )
FROM posts p
LEFT JOIN users au ON au.id = p.author_user_id
WHERE p.id = $1 AND p.status = 'published' AND p.deleted_at IS NULL`, pid, viewerStr)

	var (
		id, catID                    uuid.UUID
		status, title, excerpt, body string
		hero                         string
		pubAt                        *time.Time
		likes, comments, shares      int32
		created, updated             time.Time
		auID                         *uuid.UUID
		auName                       *string
		auHeadline, auAvatar         *string
		viewerReacted                bool
	)
	if err := row.Scan(
		&id, &catID, &status, &title, &excerpt, &body, &hero,
		&pubAt, &likes, &comments, &shares, &created, &updated,
		&auID, &auName, &auHeadline, &auAvatar,
		&viewerReacted,
	); err != nil {
		if err == pgx.ErrNoRows {
			return nil, connect.NewError(connect.CodeNotFound, fmt.Errorf("post"))
		}
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	post := &loftv1.Post{
		Id:               id.String(),
		CategoryId:       catID.String(),
		Status:           protoPublishStatus(status),
		Title:            title,
		Excerpt:          excerpt,
		Body:             body,
		HeroImageUrl:     hero,
		LikeCount:        likes,
		CommentCount:     comments,
		ShareCount:       shares,
		CreatedAtUnix:    unix(created),
		UpdatedAtUnix:    unix(updated),
		ViewerHasReacted: viewerReacted,
	}
	if pubAt != nil {
		post.PublishedAtUnix = unix(*pubAt)
	}
	if auID != nil && auName != nil {
		post.Author = userPublic(*auID, *auName, auHeadline, auAvatar)
	}
	return connect.NewResponse(&loftv1.GetPostResponse{Post: post}), nil
}

func (s *Loft) GetHomeContent(ctx context.Context, req *connect.Request[loftv1.GetHomeContentRequest]) (*connect.Response[loftv1.GetHomeContentResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	loc := strings.TrimSpace(req.Msg.GetLocale())
	if loc == "" {
		loc = "en"
	}
	rows, err := s.pool().Query(ctx, `
SELECT id, key, locale, value::text, updated_at
FROM content_blocks WHERE locale = $1 ORDER BY key`, loc)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	defer rows.Close()
	var blocks []*loftv1.ContentBlock
	for rows.Next() {
		var id uuid.UUID
		var key, locale, valJSON string
		var updated time.Time
		if err := rows.Scan(&id, &key, &locale, &valJSON, &updated); err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
		blocks = append(blocks, &loftv1.ContentBlock{
			Id: id.String(), Key: key, Locale: locale, ValueJson: valJSON, UpdatedAtUnix: unix(updated),
		})
	}
	if err := rows.Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&loftv1.GetHomeContentResponse{Blocks: blocks}), nil
}

func (s *Loft) ListBoards(ctx context.Context, _ *connect.Request[loftv1.ListBoardsRequest]) (*connect.Response[loftv1.ListBoardsResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	rows, err := s.pool().Query(ctx, `
SELECT id, slug, title, COALESCE(description, ''), sort_order, is_active
FROM boards WHERE is_active ORDER BY sort_order, title`)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	defer rows.Close()
	var boards []*loftv1.Board
	for rows.Next() {
		var id uuid.UUID
		var slug, title, desc string
		var sort int32
		var active bool
		if err := rows.Scan(&id, &slug, &title, &desc, &sort, &active); err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
		boards = append(boards, &loftv1.Board{Id: id.String(), Slug: slug, Title: title, Description: desc, SortOrder: sort, IsActive: active})
	}
	if err := rows.Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&loftv1.ListBoardsResponse{Boards: boards}), nil
}

func (s *Loft) ListBoardThreads(ctx context.Context, req *connect.Request[loftv1.ListBoardThreadsRequest]) (*connect.Response[loftv1.ListBoardThreadsResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	boardID, err := uuid.Parse(strings.TrimSpace(req.Msg.GetBoardId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("board_id"))
	}
	pageSize := int(req.Msg.GetPageSize())
	if pageSize <= 0 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}
	cursor := strings.TrimSpace(req.Msg.GetPageCursor())
	var cursorT *time.Time
	var cursorID *uuid.UUID
	if cursor != "" {
		t, id, err := decodeThreadCursor(cursor)
		if err != nil {
			return nil, connect.NewError(connect.CodeInvalidArgument, err)
		}
		cursorT = &t
		cursorID = &id
	}
	args := []any{boardID, pageSize + 1}
	idx := 3
	q := `
SELECT t.id, t.board_id, t.status::text, t.title, t.body, t.answer_post_id, t.created_at, t.updated_at,
  u.id, u.display_name, u.headline, u.avatar_url
FROM board_threads t
JOIN users u ON u.id = t.author_user_id
WHERE t.board_id = $1`
	if cursorT != nil && cursorID != nil {
		q += fmt.Sprintf(" AND (t.created_at, t.id) < ($%d::timestamptz, $%d::uuid)", idx, idx+1)
		args = append(args, *cursorT, *cursorID)
		idx += 2
	}
	q += ` ORDER BY t.created_at DESC, t.id DESC LIMIT $2`
	rows, err := s.pool().Query(ctx, q, args...)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	defer rows.Close()
	var threads []*loftv1.BoardThread
	for rows.Next() {
		th, err := scanBoardThread(rows)
		if err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
		threads = append(threads, th)
	}
	if err := rows.Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	var next string
	if len(threads) > pageSize {
		last := threads[pageSize-1]
		threads = threads[:pageSize]
		id, _ := uuid.Parse(last.Id)
		next = encodeThreadCursor(time.Unix(last.CreatedAtUnix, 0).UTC(), id)
	}
	return connect.NewResponse(&loftv1.ListBoardThreadsResponse{Threads: threads, NextPageCursor: next}), nil
}

func decodeThreadCursor(s string) (time.Time, uuid.UUID, error) {
	return decodePostCursor(s) // same format unix|uuid
}

func encodeThreadCursor(t time.Time, id uuid.UUID) string {
	return encodePostCursor(t, id)
}

func scanBoardThread(rows pgx.Rows) (*loftv1.BoardThread, error) {
	var (
		id, bid, uid        uuid.UUID
		status, title, body string
		answerID            *uuid.UUID
		created, updated    time.Time
		uAvatar, uHeadline  *string
		uName               string
	)
	if err := rows.Scan(
		&id, &bid, &status, &title, &body, &answerID, &created, &updated,
		&uid, &uName, &uHeadline, &uAvatar,
	); err != nil {
		return nil, err
	}
	th := &loftv1.BoardThread{
		Id: id.String(), BoardId: bid.String(), Author: userPublic(uid, uName, uHeadline, uAvatar),
		Title: title, Body: body, Status: protoBoardThreadStatus(status),
		CreatedAtUnix: unix(created), UpdatedAtUnix: unix(updated),
	}
	if answerID != nil {
		th.AnswerPostId = answerID.String()
	}
	return th, nil
}

func (s *Loft) ListPostComments(ctx context.Context, req *connect.Request[loftv1.ListPostCommentsRequest]) (*connect.Response[loftv1.ListPostCommentsResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	postID, err := uuid.Parse(strings.TrimSpace(req.Msg.GetPostId()))
	if err != nil {
		return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("post_id"))
	}
	pageSize := int(req.Msg.GetPageSize())
	if pageSize <= 0 {
		pageSize = 50
	}
	if pageSize > 200 {
		pageSize = 200
	}
	cursor := strings.TrimSpace(req.Msg.GetPageCursor())
	var cursorT *time.Time
	var cursorID *uuid.UUID
	if cursor != "" {
		t, id, err := decodePostCursor(cursor)
		if err != nil {
			return nil, connect.NewError(connect.CodeInvalidArgument, err)
		}
		cursorT = &t
		cursorID = &id
	}
	args := []any{postID, pageSize + 1}
	idx := 3
	q := `
SELECT c.id, c.post_id, c.body, c.created_at, c.updated_at,
  u.id, u.display_name, u.headline, u.avatar_url
FROM comments c
JOIN users u ON u.id = c.author_user_id
WHERE c.post_id = $1 AND c.deleted_at IS NULL`
	if cursorT != nil && cursorID != nil {
		q += fmt.Sprintf(" AND (c.created_at, c.id) < ($%d::timestamptz, $%d::uuid)", idx, idx+1)
		args = append(args, *cursorT, *cursorID)
		idx += 2
	}
	q += ` ORDER BY c.created_at DESC, c.id DESC LIMIT $2`
	rows, err := s.pool().Query(ctx, q, args...)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	defer rows.Close()
	var list []*loftv1.Comment
	for rows.Next() {
		var id, pid, uid uuid.UUID
		var body string
		var created, updated time.Time
		var uName string
		var uHeadline, uAvatar *string
		if err := rows.Scan(&id, &pid, &body, &created, &updated, &uid, &uName, &uHeadline, &uAvatar); err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
		list = append(list, &loftv1.Comment{
			Id: id.String(), PostId: pid.String(), Author: userPublic(uid, uName, uHeadline, uAvatar),
			Body: body, CreatedAtUnix: unix(created), UpdatedAtUnix: unix(updated),
		})
	}
	if err := rows.Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	var next string
	if len(list) > pageSize {
		last := list[pageSize-1]
		list = list[:pageSize]
		cid, _ := uuid.Parse(last.Id)
		next = encodePostCursor(time.Unix(last.CreatedAtUnix, 0).UTC(), cid)
	}
	return connect.NewResponse(&loftv1.ListPostCommentsResponse{Comments: list, NextPageCursor: next}), nil
}
