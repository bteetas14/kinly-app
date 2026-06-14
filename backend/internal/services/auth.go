package services

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"kinly/backend/internal/dto"
	"kinly/backend/internal/httpx"
	"kinly/backend/internal/repositories"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type Claims struct {
	UserID string `json:"user_id"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

type AuthService struct {
	store  *repositories.Store
	secret []byte
	issuer string
	ttl    time.Duration
}

func NewAuthService(store *repositories.Store, secret, issuer string, ttl time.Duration) *AuthService {
	return &AuthService{store: store, secret: []byte(secret), issuer: issuer, ttl: ttl}
}

func (s *AuthService) Signup(ctx context.Context, req dto.SignupRequest) (dto.AuthResponse, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return dto.AuthResponse{}, err
	}
	user, err := s.store.CreateUser(ctx, req.Email, req.Username, string(hash))
	if err != nil {
		return dto.AuthResponse{}, httpx.ErrConflict
	}
	token, err := s.issueToken(user.ID, user.Role)
	if err != nil {
		return dto.AuthResponse{}, err
	}
	profile, err := s.store.Profile(ctx, user.ID)
	if err != nil {
		return dto.AuthResponse{}, err
	}
	return dto.AuthResponse{Token: token, User: profile}, nil
}

func (s *AuthService) Login(ctx context.Context, req dto.LoginRequest) (dto.AuthResponse, error) {
	user, err := s.store.UserByEmail(ctx, req.Email)
	if errors.Is(err, sql.ErrNoRows) {
		return dto.AuthResponse{}, httpx.ErrUnauthorized
	}
	if err != nil {
		return dto.AuthResponse{}, err
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return dto.AuthResponse{}, httpx.ErrUnauthorized
	}
	token, err := s.issueToken(user.ID, user.Role)
	if err != nil {
		return dto.AuthResponse{}, err
	}
	profile, err := s.store.Profile(ctx, user.ID)
	if err != nil {
		return dto.AuthResponse{}, err
	}
	return dto.AuthResponse{Token: token, User: profile}, nil
}

func (s *AuthService) Logout(ctx context.Context, tokenID, userID string, expiresAt time.Time) error {
	if tokenID == "" || userID == "" {
		return httpx.ErrUnauthorized
	}
	return s.store.RevokeToken(ctx, tokenID, userID, expiresAt)
}

func (s *AuthService) ParseToken(ctx context.Context, tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (any, error) {
		return s.secret, nil
	}, jwt.WithIssuer(s.issuer), jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}))
	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, httpx.ErrUnauthorized
	}
	revoked, err := s.store.IsTokenRevoked(ctx, claims.ID)
	if err != nil {
		return nil, err
	}
	if revoked {
		return nil, httpx.ErrUnauthorized
	}
	return claims, nil
}

func (s *AuthService) issueToken(userID, role string) (string, error) {
	now := time.Now()
	claims := Claims{
		UserID: userID,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        uuid.NewString(),
			Issuer:    s.issuer,
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.ttl)),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(s.secret)
}
