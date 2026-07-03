package config

import (
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Env                string
	Port               string
	DatabaseURL        string
	JWTSecret          string
	JWTIssuer          string
	JWTTTL             time.Duration
	CORSAllowedOrigins []string
	S3Endpoint         string
	S3Bucket           string
	S3AccessKey        string
	S3SecretKey        string
	S3Region           string
	S3UsePathStyle     bool
}

func Load() Config {
	ttlMinutes := getInt("JWT_TTL_MINUTES", 60*24*30)
	return Config{
		Env:                get("APP_ENV", "local"),
		Port:               get("PORT", "8080"),
		DatabaseURL:        get("DATABASE_URL", "postgres://kinly:kinly@localhost:5432/kinly?sslmode=disable"),
		JWTSecret:          get("JWT_SECRET", "local-development-secret-change-me"),
		JWTIssuer:          get("JWT_ISSUER", "kinly"),
		JWTTTL:             time.Duration(ttlMinutes) * time.Minute,
		CORSAllowedOrigins: splitCSV(get("CORS_ALLOWED_ORIGINS", "*")),
		S3Endpoint:         get("S3_ENDPOINT", "http://localhost:9000"),
		S3Bucket:           get("S3_BUCKET", "kinly-images"),
		S3AccessKey:        get("S3_ACCESS_KEY", "kinly"),
		S3SecretKey:        get("S3_SECRET_KEY", "kinlysecret"),
		S3Region:           get("S3_REGION", "us-east-1"),
		S3UsePathStyle:     getBool("S3_USE_PATH_STYLE", true),
	}
}

func (c Config) LogLevel() slog.Level {
	if c.Env == "local" {
		return slog.LevelDebug
	}
	return slog.LevelInfo
}

func (c Config) Validate() error {
	if c.Env != "production" {
		return nil
	}

	if c.DatabaseURL == "" || strings.Contains(c.DatabaseURL, "localhost") {
		return fmt.Errorf("DATABASE_URL must be set to a production database")
	}
	if len(c.JWTSecret) < 32 || c.JWTSecret == "local-development-secret-change-me" {
		return fmt.Errorf("JWT_SECRET must be a production secret with at least 32 characters")
	}
	if len(c.CORSAllowedOrigins) == 0 {
		return fmt.Errorf("CORS_ALLOWED_ORIGINS must list the production web origins")
	}
	for _, origin := range c.CORSAllowedOrigins {
		if origin == "*" {
			return fmt.Errorf("CORS_ALLOWED_ORIGINS cannot contain * in production")
		}
		if !strings.HasPrefix(origin, "https://") {
			return fmt.Errorf("CORS_ALLOWED_ORIGINS must use https origins in production: %s", origin)
		}
	}
	if c.S3Endpoint == "" || strings.Contains(c.S3Endpoint, "localhost") {
		return fmt.Errorf("S3_ENDPOINT must be set to production object storage")
	}
	if c.S3Bucket == "" || c.S3AccessKey == "" || c.S3SecretKey == "" || c.S3Region == "" {
		return fmt.Errorf("S3_BUCKET, S3_ACCESS_KEY, S3_SECRET_KEY, and S3_REGION are required in production")
	}
	return nil
}

func get(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func getInt(key string, fallback int) int {
	raw := os.Getenv(key)
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return fallback
	}
	return value
}

func getBool(key string, fallback bool) bool {
	raw := os.Getenv(key)
	if raw == "" {
		return fallback
	}
	value, err := strconv.ParseBool(raw)
	if err != nil {
		return fallback
	}
	return value
}

func splitCSV(raw string) []string {
	parts := strings.Split(raw, ",")
	values := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			values = append(values, part)
		}
	}
	return values
}
