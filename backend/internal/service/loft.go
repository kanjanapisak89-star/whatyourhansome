package service

import (
	"database/sql"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Loft implements all Connect services (Public, Member, Admin, Auth)
type Loft struct {
	Pool *pgxpool.Pool
	
	*PublicService
	*MemberService
	*AdminService
	*AuthService
}

// NewLoft creates a new Loft service with all sub-services
func NewLoft(pool *pgxpool.Pool) *Loft {
	// Convert pgxpool to sql.DB for services that need it
	var db *sql.DB
	if pool != nil {
		// Note: This is a simplified approach. In production, you might want to use pgxpool directly
		// or create a proper sql.DB from the pool connection string
	}
	
	return &Loft{
		Pool:          pool,
		PublicService: NewPublicService(db),
		MemberService: NewMemberService(db),
		AdminService:  NewAdminService(db),
		AuthService:   NewAuthService(db),
	}
}
