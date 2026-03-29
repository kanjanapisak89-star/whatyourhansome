package auth

import (
	"context"
	"errors"

	"connectrpc.com/connect"
	"github.com/medlab/loft/backend/gen/proto/loft/v1/loftv1connect"
)

// NewOptionalUserInterceptor attaches AppUser for reads when a valid Bearer token is sent (e.g. ListPosts, GetPost for viewer_has_reacted).
// Invalid or missing tokens proceed as guests. Blocked users still get AppUser attached so the client can distinguish state.
func NewOptionalUserInterceptor(opts InterceptorOptions) connect.UnaryInterceptorFunc {
	withOptional := map[string]struct{}{
		loftv1connect.PublicServiceGetFeedProcedure: {},
		loftv1connect.PublicServiceGetPostProcedure: {},
	}

	return func(next connect.UnaryFunc) connect.UnaryFunc {
		return func(ctx context.Context, req connect.AnyRequest) (connect.AnyResponse, error) {
			if _, ok := withOptional[req.Spec().Procedure]; !ok {
				return next(ctx, req)
			}
			if opts.Verifier == nil || opts.Syncer == nil {
				return next(ctx, req)
			}
			raw := req.Header().Get(authorizationHeader)
			idToken, ok := bearerToken(raw)
			if !ok {
				return next(ctx, req)
			}
			vt, err := opts.Verifier.VerifyIDToken(ctx, idToken)
			if err != nil {
				return next(ctx, req)
			}
			ctx = WithFirebaseUID(ctx, vt.UID)
			u, err := opts.Syncer.SyncUser(ctx, vt)
			if err != nil {
				if errors.Is(err, ErrUserBlocked) && u != nil {
					ctx = WithAppUser(ctx, u)
				}
				return next(ctx, req)
			}
			ctx = WithAppUser(ctx, u)
			return next(ctx, req)
		}
	}
}
