package config

import "testing"

func TestValidateAllowsLocalDefaults(t *testing.T) {
	cfg := Load()

	if err := cfg.Validate(); err != nil {
		t.Fatalf("expected local defaults to validate, got %v", err)
	}
}

func TestValidateRejectsProductionDefaults(t *testing.T) {
	cfg := Load()
	cfg.Env = "production"

	if err := cfg.Validate(); err == nil {
		t.Fatal("expected production defaults to be rejected")
	}
}

func TestValidateAcceptsProductionConfiguration(t *testing.T) {
	cfg := Config{
		Env:                "production",
		DatabaseURL:        "postgres://kinly:secret@db.example.com:5432/kinly?sslmode=require",
		JWTSecret:          "replace-with-a-real-32-character-secret",
		CORSAllowedOrigins: []string{"https://kinly.example.com"},
		S3Endpoint:         "https://s3.example.com",
		S3Bucket:           "kinly-images",
		S3AccessKey:        "access-key",
		S3SecretKey:        "secret-key",
		S3Region:           "us-east-1",
	}

	if err := cfg.Validate(); err != nil {
		t.Fatalf("expected production config to validate, got %v", err)
	}
}
