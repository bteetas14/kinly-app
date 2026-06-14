package services

import (
	"context"
	"database/sql"
	"errors"

	"kinly/backend/internal/dto"
	"kinly/backend/internal/httpx"
	"kinly/backend/internal/repositories"
)

type UserService struct {
	store *repositories.Store
}

func NewUserService(store *repositories.Store) *UserService {
	return &UserService{store: store}
}

func (s *UserService) Profile(ctx context.Context, id string) (dto.UserProfile, error) {
	profile, err := s.store.Profile(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return dto.UserProfile{}, httpx.ErrNotFound
	}
	return profile, err
}

func (s *UserService) UpdateProfile(ctx context.Context, userID string, req dto.UpdateProfileRequest) (dto.UserProfile, error) {
	_, err := s.store.UpdateProfile(ctx, userID, req.AvatarURL, req.Bio)
	if err != nil {
		return dto.UserProfile{}, err
	}
	return s.Profile(ctx, userID)
}
