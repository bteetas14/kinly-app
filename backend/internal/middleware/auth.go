package middleware

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"kinly/backend/internal/httpx"
	"kinly/backend/internal/services"

	"github.com/gin-gonic/gin"
)

type contextKey string

const (
	userIDKey contextKey = "user_id"
	roleKey   contextKey = "role"
	tokenID   contextKey = "token_id"
)

func Auth(auth *services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			httpx.Fail(c, httpx.ErrUnauthorized)
			return
		}

		claims, err := auth.ParseToken(c.Request.Context(), strings.TrimPrefix(header, "Bearer "))
		if err != nil {
			httpx.Fail(c, httpx.ErrUnauthorized)
			return
		}

		ctx := context.WithValue(c.Request.Context(), userIDKey, claims.UserID)
		ctx = context.WithValue(ctx, roleKey, claims.Role)
		ctx = context.WithValue(ctx, tokenID, claims.ID)
		c.Request = c.Request.WithContext(ctx)
		c.Set("user_id", claims.UserID)
		c.Set("role", claims.Role)
		c.Set("token_id", claims.ID)
		c.Next()
	}
}

func OptionalAuth(auth *services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			c.Next()
			return
		}
		claims, err := auth.ParseToken(c.Request.Context(), strings.TrimPrefix(header, "Bearer "))
		if err == nil {
			c.Set("user_id", claims.UserID)
			c.Set("role", claims.Role)
			c.Set("token_id", claims.ID)
		}
		c.Next()
	}
}

func RequireRole(roles ...string) gin.HandlerFunc {
	allowed := map[string]struct{}{}
	for _, role := range roles {
		allowed[role] = struct{}{}
	}
	return func(c *gin.Context) {
		role := CurrentRole(c)
		if _, ok := allowed[role]; !ok {
			httpx.Fail(c, httpx.ErrForbidden)
			return
		}
		c.Next()
	}
}

func CurrentUserID(c *gin.Context) (string, error) {
	value, ok := c.Get("user_id")
	if !ok {
		return "", errors.New("missing user id")
	}
	userID, ok := value.(string)
	if !ok || userID == "" {
		return "", errors.New("invalid user id")
	}
	return userID, nil
}

func CurrentRole(c *gin.Context) string {
	value, ok := c.Get("role")
	if !ok {
		return ""
	}
	role, _ := value.(string)
	return role
}

func CurrentTokenID(c *gin.Context) string {
	value, ok := c.Get("token_id")
	if !ok {
		return ""
	}
	token, _ := value.(string)
	return token
}

func MustUserID(c *gin.Context) (string, bool) {
	userID, err := CurrentUserID(c)
	if err != nil {
		c.AbortWithStatusJSON(http.StatusUnauthorized, httpx.ErrorBody{Error: httpx.APIError{Code: "unauthorized", Message: "Authentication is required."}})
		return "", false
	}
	return userID, true
}
