package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"connectrpc.com/connect"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/medlab/loft/backend/gen/proto/loft/v1/loftv1connect"
	"github.com/medlab/loft/backend/internal/auth"
	"github.com/medlab/loft/backend/internal/db"
	"github.com/medlab/loft/backend/internal/service"
)

func main() {
	ctx := context.Background()

	fbCreds := strings.TrimSpace(os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"))
	verifier, err := auth.NewFirebaseVerifier(ctx, fbCreds)
	if err != nil {
		log.Fatalf("firebase: %v", err)
	}

	var pool *pgxpool.Pool
	syncerOpts := auth.InterceptorOptions{Verifier: verifier}
	p, perr := db.NewPool(ctx)
	if perr != nil {
		log.Printf("database: %v (public RPCs return unavailable)", perr)
	} else {
		pool = p
		defer pool.Close()
		syncerOpts.Syncer = auth.NewUserSyncer(pool)
	}

	loftSvc := &service.Loft{Pool: pool}
	interceptors := connect.WithInterceptors(
		auth.NewOptionalUserInterceptor(syncerOpts),
		auth.NewUnaryInterceptor(syncerOpts),
	)

	mux := http.NewServeMux()
	reg := []func() (string, http.Handler){
		func() (string, http.Handler) { return loftv1connect.NewPublicServiceHandler(loftSvc, interceptors) },
		func() (string, http.Handler) { return loftv1connect.NewMemberServiceHandler(loftSvc, interceptors) },
		func() (string, http.Handler) { return loftv1connect.NewAdminServiceHandler(loftSvc, interceptors) },
	}
	for _, f := range reg {
		path, h := f()
		mux.Handle(path, h)
	}

	addr := strings.TrimSpace(os.Getenv("PORT"))
	if addr == "" {
		addr = ":8080"
	} else if !strings.Contains(addr, ":") {
		addr = ":" + addr
	}
	srv := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}

	go func() {
		log.Printf("listening on %s", srv.Addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutdownCtx)
}
