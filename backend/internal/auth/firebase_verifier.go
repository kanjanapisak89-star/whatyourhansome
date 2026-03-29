package auth

import (
	"context"
	"fmt"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

// FirebaseVerifier verifies Firebase ID tokens using the Admin SDK.
type FirebaseVerifier struct {
	client *auth.Client
}

// NewFirebaseVerifier uses Application Default Credentials or GOOGLE_APPLICATION_CREDENTIALS.
func NewFirebaseVerifier(ctx context.Context, credentialsFile string) (*FirebaseVerifier, error) {
	var opts []option.ClientOption
	creds := strings.TrimSpace(credentialsFile)
	
	if creds != "" {
		// Check if it's JSON content (starts with {) or a file path
		if strings.HasPrefix(creds, "{") {
			// It's JSON content, use it directly
			opts = append(opts, option.WithCredentialsJSON([]byte(creds)))
		} else {
			// It's a file path
			opts = append(opts, option.WithCredentialsFile(creds))
		}
	}
	
	app, err := firebase.NewApp(ctx, nil, opts...)
	if err != nil {
		return nil, fmt.Errorf("firebase app: %w", err)
	}
	ac, err := app.Auth(ctx)
	if err != nil {
		return nil, fmt.Errorf("firebase auth: %w", err)
	}
	return &FirebaseVerifier{client: ac}, nil
}

// VerifyIDToken validates the bearer token and returns claims needed for user sync.
func (v *FirebaseVerifier) VerifyIDToken(ctx context.Context, idToken string) (*VerifiedToken, error) {
	tok, err := v.client.VerifyIDToken(ctx, idToken)
	if err != nil {
		return nil, err
	}
	email, _ := tok.Claims["email"].(string)
	name, _ := tok.Claims["name"].(string)
	picture, _ := tok.Claims["picture"].(string)
	provider, err := signInProviderFromClaims(tok.Claims)
	if err != nil {
		return nil, err
	}
	return &VerifiedToken{
		UID:          tok.UID,
		Email:        email,
		DisplayName:  name,
		PhotoURL:     picture,
		AuthProvider: provider,
	}, nil
}

// VerifiedToken holds decoded identity after Firebase verification.
type VerifiedToken struct {
	UID          string
	Email        string
	DisplayName  string
	PhotoURL     string
	AuthProvider string // "google" or "facebook"
}

func signInProviderFromClaims(claims map[string]interface{}) (string, error) {
	firebaseClaim, ok := claims["firebase"].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("auth: missing firebase claim")
	}
	signIn, _ := firebaseClaim["sign_in_provider"].(string)
	switch signIn {
	case "google.com":
		return "google", nil
	case "facebook.com":
		return "facebook", nil
	default:
		return "", fmt.Errorf("auth: unsupported sign_in_provider %q (need google.com or facebook.com)", signIn)
	}
}
