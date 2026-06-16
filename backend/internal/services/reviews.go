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
	owns, err := s.store.UserOwnsProductBrand(ctx, userID, req.ProductID)
	if err != nil {
		return models.Review{}, err
	}
	if owns {
		return models.Review{}, httpx.ErrForbidden
	}
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
	productID, err := s.store.ReviewProductID(ctx, reviewID)
	if errors.Is(err, sql.ErrNoRows) {
		return httpx.ErrNotFound
	}
	if err != nil {
		return err
	}
	owns, err := s.store.UserOwnsProductBrand(ctx, userID, productID)
	if err != nil {
		return err
	}
	if owns {
		return httpx.ErrForbidden
	}
	return s.store.MarkReviewHelpful(ctx, userID, reviewID)
}

func (s *ReviewService) Comment(ctx context.Context, userID, reviewID, body string) error {
	return s.store.AddReviewComment(ctx, userID, reviewID, body)
}

func (s *ReviewService) Followup(ctx context.Context, userID, reviewID string, req dto.ReviewFollowupRequest) (models.ReviewFollowup, error) {
	followup, err := s.store.AddReviewFollowup(ctx, userID, reviewID, req)
	if errors.Is(err, sql.ErrNoRows) {
		return models.ReviewFollowup{}, httpx.ErrNotFound
	}
	return followup, err
}

func (s *ReviewService) Report(ctx context.Context, userID, reviewID string, req dto.ReviewReportRequest) error {
	return s.store.ReportReview(ctx, userID, reviewID, req)
}
