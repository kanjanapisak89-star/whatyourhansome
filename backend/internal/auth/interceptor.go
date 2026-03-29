package auth

import (
	"context"
	"errors"
	"strings"

	"connectrpc.com/connect"
	"github.com/medlab/loft/backend/gen/proto/loft/v1/loftv1connect"
)

const authorizationHeader = "Authorization"

// InterceptorOptions configures Connect interceptors for Firebase + DB sync.
type InterceptorOptions struct {
	Verifier   *FirebaseVerifier
	Syncer     *UserSyncer
	SkipVerify bool // tests: verify token but skip DB sync
}

// NewUnaryInterceptor enforces auth for MemberService and AdminService procedures.
func NewUnaryInterceptor(opts InterceptorOptions) connect.UnaryInterceptorFunc {
	memberProcedures := map[string]struct{}{
		loftv1connect.MemberServiceToggleReactionProcedure:       {},
		loftv1connect.MemberServiceCreateCommentProcedure:        {},
		loftv1connect.MemberServiceCreateBoardQuestionProcedure:  {},
		loftv1connect.MemberServiceGetMyQuestionsProcedure:       {},
		loftv1connect.MemberServiceGetCurrentUserProcedure:       {},
	}
	adminProcedures := map[string]struct{}{
		loftv1connect.AdminServiceCreatePostProcedure:            {},
		loftv1connect.AdminServiceUpdatePostProcedure:            {},
		loftv1connect.AdminServiceDeletePostProcedure:            {},
		loftv1connect.AdminServiceDeleteCommentProcedure:         {},
		loftv1connect.AdminServiceBlockUserProcedure:             {},
		loftv1connect.AdminServiceUnblockUserProcedure:           {},
		loftv1connect.AdminServiceGetBoardQuestionsProcedure:     {},
		loftv1connect.AdminServiceRespondToQuestionProcedure:     {},
	}

	return func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			proc := req.Spec().Procedure
			_, needsMember := memberProcedures[proc]
			_, needsAdmin := adminProcedures[proc]
			if !needsMember && !needsAdmin {
				return next(ctx, req)
			}

			if opts.Verifier == nil {
				return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("auth verifier not configured"))
			}

			raw := req.Header().Get(authorizationHeader)
			idToken, ok := bearerToken(raw)
			if !ok {
				return nil, connect.NewError(connect.CodeUnauthenticated, errors.New("missing bearer token"))
			}

			vt, err := opts.Verifier.VerifyIDToken(ctx, idToken)
			if err != nil {
				return nil, connect.NewError(connect.CodeUnauthenticated, err)
			}
			ctx = WithFirebaseUID(ctx, vt.UID)

			if opts.SkipVerify {
				return next(ctx, req)
			}
			if opts.Syncer == nil {
				return nil, connect.NewError(connect.CodeFailedPrecondition, errors.New("user sync not configured"))
			}

			u, err := opts.Syncer.SyncUser(ctx, vt)
			if err != nil {
				if errors.Is(err, ErrUserBlocked) {
					// Still attach user so handlers can return a tailored message if needed.
					if u != nil {
						ctx = WithAppUser(ctx, u)
					}
					return nil, connect.NewError(connect.CodePermissionDenied, err)
				}
				return nil, connect.NewError(connect.CodeInternal, err)
			}
			ctx = WithAppUser(ctx, u)

			if needsAdmin && !u.IsAdmin() {
				return nil, connect.NewError(connect.CodePermissionDenied, errors.New("admin role required"))
			}

			return next(ctx, req)
		}
	}
}

func bearerToken(header string) (string, bool) {
	h := strings.TrimSpace(header)
	const prefix = "Bearer "
	if len(h) < len(prefix) || !strings.EqualFold(h[:len(prefix)], prefix) {
		return "", false
	}
	tok := strings.TrimSpace(h[len(prefix):])
	return tok, tok != ""
}
