package service

import (
	"context"
	"fmt"
	"strings"
	"time"

	"connectrpc.com/connect"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	loftv1 "github.com/medlab/loft/backend/gen/proto/loft/v1"
	"github.com/medlab/loft/backend/internal/auth"
)

// Loft implements Connect Public, Member, and Admin services.
type Loft struct {
	Pool *pgxpool.Pool
}

func (s *Loft) pool() *pgxpool.Pool {
	return s.Pool
}

func (s *Loft) dbErr() error {
	return connect.NewError(connect.CodeUnavailable, fmt.Errorf("database not configured"))
}

func viewerIDString(ctx context.Context) string {
	if u := auth.AppUserFromContext(ctx); u != nil {
		return u.ID.String()
	}
	return ""
}

// --- PublicService ---

func (s *Loft) ListCategories(ctx context.Context, _ *connect.Request[loftv1.ListCategoriesRequest]) (*connect.Response[loftv1.ListCategoriesResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	rows, err := s.pool().Query(ctx, `
SELECT id, slug, label, sort_order, COALESCE(icon_key, ''), is_active
FROM categories WHERE is_active ORDER BY sort_order, label`)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	defer rows.Close()
	var out []*loftv1.Category
	for rows.Next() {
		var id uuid.UUID
		var slug, label string
		var sort int32
		var icon string
		var active bool
		if err := rows.Scan(&id, &slug, &label, &sort, &icon, &active); err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
		out = append(out, &loftv1.Category{Id: id.String(), Slug: slug, Label: label, SortOrder: sort, IconKey: icon, IsActive: active})
	}
	if err := rows.Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	return connect.NewResponse(&loftv1.ListCategoriesResponse{Categories: out}), nil
}

func (s *Loft) ListPosts(ctx context.Context, req *connect.Request[loftv1.ListPostsRequest]) (*connect.Response[loftv1.ListPostsResponse], error) {
	if s.pool() == nil {
		return nil, s.dbErr()
	}
	pageSize := int(req.Msg.GetPageSize())
	if pageSize <= 0 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}
	catFilter := strings.TrimSpace(req.Msg.GetCategoryId())
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
	viewerStr := viewerIDString(ctx)
	args := []any{viewerStr, pageSize + 1}
	idx := 3
	q := `
SELECT p.id, p.category_id, p.status::text, p.title, p.excerpt, p.body, p.hero_image_url,
  p.published_at, p.like_count, p.comment_count, p.share_count, p.created_at, p.updated_at,
  au.id, au.display_name, au.headline, au.avatar_url,
  EXISTS (
    SELECT 1 FROM post_reactions pr
    WHERE pr.post_id = p.id AND pr.reaction_type = 'heart'
      AND NULLIF($1::text, '') IS NOT NULL AND pr.user_id = $1::uuid
  )
FROM posts p
LEFT JOIN users au ON au.id = p.author_user_id
WHERE p.status = 'published' AND p.deleted_at IS NULL`
	if catFilter != "" {
		cid, err := uuid.Parse(catFilter)
		if err != nil {
			return nil, connect.NewError(connect.CodeInvalidArgument, fmt.Errorf("category_id"))
		}
		q += fmt.Sprintf(" AND p.category_id = $%d", idx)
		args = append(args, cid)
		idx++
	}
	if cursorT != nil && cursorID != nil {
		q += fmt.Sprintf(" AND (p.published_at, p.id) < ($%d::timestamptz, $%d::uuid)", idx, idx+1)
		args = append(args, *cursorT, *cursorID)
		idx += 2
	}
	q += ` ORDER BY p.published_at DESC, p.id DESC LIMIT $2`

	rows, err := s.pool().Query(ctx, q, args...)
	if err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	defer rows.Close()
	var posts []*loftv1.Post
	for rows.Next() {
		p, err := scanPostRow(rows)
		if err != nil {
			return nil, connect.NewError(connect.CodeInternal, err)
		}
		posts = append(posts, p)
	}
	if err := rows.Err(); err != nil {
		return nil, connect.NewError(connect.CodeInternal, err)
	}
	var nextCur string
	if len(posts) > pageSize {
		last := posts[pageSize-1]
		posts = posts[:pageSize]
		nextCur = encodePostCursorFromProto(last)
	}
	return connect.NewResponse(&loftv1.ListPostsResponse{Posts: posts, NextPageCursor: nextCur}), nil
}

func decodePostCursor(s string) (time.Time, uuid.UUID, error) {
	parts := strings.SplitN(s, "|", 2)
	if len(parts) != 2 {
		return time.Time{}, uuid.Nil, fmt.Errorf("invalid cursor")
	}
	var sec int64
	if _, err := fmt.Sscanf(parts[0], "%d", &sec); err != nil {
		return time.Time{}, uuid.Nil, fmt.Errorf("invalid cursor time")
	}
	id, err := uuid.Parse(parts[1])
	if err != nil {
		return time.Time{}, uuid.Nil, err
	}
	return time.Unix(sec, 0).UTC(), id, nil
}

func encodePostCursor(t time.Time, id uuid.UUID) string {
	return fmt.Sprintf("%d|%s", t.Unix(), id.String())
}

func encodePostCursorFromProto(p *loftv1.Post) string {
	id, _ := uuid.Parse(p.Id)
	t := time.Unix(p.PublishedAtUnix, 0).UTC()
	return encodePostCursor(t, id)
}

func scanPostRow(rows pgx.Rows) (*loftv1.Post, error) {
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
	if err := rows.Scan(
		&id, &catID, &status, &title, &excerpt, &body, &hero,
		&pubAt, &likes, &comments, &shares, &created, &updated,
		&auID, &auName, &auHeadline, &auAvatar,
		&viewerReacted,
	); err != nil {
		return nil, err
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
	return post, nil
}
