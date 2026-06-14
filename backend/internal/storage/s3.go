package storage

import "context"

type ImageStorage interface {
	PresignedUploadURL(ctx context.Context, key string) (string, error)
}

type S3Config struct {
	Endpoint     string
	Bucket       string
	AccessKey    string
	SecretKey    string
	Region       string
	UsePathStyle bool
}

type S3Storage struct {
	cfg S3Config
}

func NewS3Storage(cfg S3Config) *S3Storage {
	return &S3Storage{cfg: cfg}
}

func (s *S3Storage) PresignedUploadURL(ctx context.Context, key string) (string, error) {
	_ = ctx
	return s.cfg.Endpoint + "/" + s.cfg.Bucket + "/" + key, nil
}
