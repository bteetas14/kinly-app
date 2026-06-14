package middleware

import (
	"log/slog"
	"net/http"
	"runtime/debug"
	"strings"
	"time"

	"kinly/backend/internal/config"
	"kinly/backend/internal/httpx"

	"github.com/gin-gonic/gin"
)

func RequestLogger(logger *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		logger.Info("request",
			"method", c.Request.Method,
			"path", c.Request.URL.Path,
			"status", c.Writer.Status(),
			"duration_ms", time.Since(start).Milliseconds(),
			"client_ip", c.ClientIP(),
		)
	}
}

func Recovery(logger *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if recovered := recover(); recovered != nil {
				logger.Error("panic", "error", recovered, "stack", string(debug.Stack()))
				httpx.Fail(c, httpx.ErrInvalid)
			}
		}()
		c.Next()
	}
}

func CORS(cfg config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if isOriginAllowed(origin, cfg.CORSAllowedOrigins) {
			c.Header("Access-Control-Allow-Origin", origin)
		} else if len(cfg.CORSAllowedOrigins) == 1 && cfg.CORSAllowedOrigins[0] == "*" {
			c.Header("Access-Control-Allow-Origin", "*")
		}
		c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

func isOriginAllowed(origin string, allowed []string) bool {
	if origin == "" {
		return false
	}
	for _, candidate := range allowed {
		if candidate == "*" || strings.EqualFold(candidate, origin) {
			return true
		}
	}
	return false
}
