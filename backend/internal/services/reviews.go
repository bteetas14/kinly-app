package services

import (
	"context"
	"database/sql"
	"errors"

	"kinly/backend/internal/dto"
	"kinly/backend/internal/httpx"
	"kinly/backend/internal/models"
	"kinly/backend/internal/repositories"
)

type ReviewService struct {
	store *repositories.Store
}

func NewReviewService(store *repositories.Store) *ReviewService {
	return &ReviewService{store: store}
}

func (s *ReviewService) Create(ctx context.Context, userID string, req dto.CreateReviewRequest) (models.Review, error) {
	return s.store.CreateReview(ctx, userID, req)
}

func (s *ReviewService) List(ctx context.Context, productID, sort string, limit, offset int) ([]models.Review, int64, error) {
	return s.store.ListReviews(ctx, productID, sort, limit, offset)
}

func (s *ReviewService) Delete(ctx context.Context, userID, reviewID string) error {
	err := s.store.DeleteReview(ctx, userID, reviewID)
	if errors.Is(err, sql.ErrNoRows) {
		return httpx.ErrNotFound
	}
	return err
}

func (s *ReviewService) Helpful(ctx context.Context, userID, reviewID string) error {
	return s.store.MarkReviewHelpful(ctx, userID, reviewID)
}

func (s *ReviewService) Comment(ctx context.Context, userID, reviewID, body string) error {
	return s.store.AddReviewComment(ctx, userID, reviewID, body)
}
