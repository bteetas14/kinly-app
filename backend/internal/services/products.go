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

type ProductService struct {
	store *repositories.Store
}

type ProductDetail struct {
	Product         models.Product   `json:"product"`
	TopReviews      []models.Review  `json:"top_reviews"`
	RelatedProducts []models.Product `json:"related_products"`
	PositiveReviews []models.Review  `json:"positive_reviews"`
	CriticalReviews []models.Review  `json:"critical_reviews"`
}

func NewProductService(store *repositories.Store) *ProductService {
	return &ProductService{store: store}
}

func (s *ProductService) List(ctx context.Context, filters dto.ProductFilters, limit, offset int) ([]models.Product, int64, error) {
	return s.store.ListProducts(ctx, filters, limit, offset)
}

func (s *ProductService) Categories(ctx context.Context) ([]models.Category, error) {
	return s.store.Categories(ctx)
}

func (s *ProductService) Brands(ctx context.Context, limit, offset int) ([]models.Brand, int64, error) {
	return s.store.Brands(ctx, limit, offset)
}

func (s *ProductService) Brand(ctx context.Context, id string) (models.Brand, error) {
	brand, err := s.store.BrandByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return models.Brand{}, httpx.ErrNotFound
	}
	return brand, err
}

func (s *ProductService) BrandProducts(ctx context.Context, id string, limit, offset int) ([]models.Product, int64, error) {
	brand, err := s.Brand(ctx, id)
	if err != nil {
		return nil, 0, err
	}
	return s.store.ListProducts(ctx, dto.ProductFilters{Brand: brand.Name, Sort: "most_reviewed"}, limit, offset)
}

func (s *ProductService) Search(ctx context.Context, query string, limit, offset int) ([]models.Product, int64, error) {
	return s.store.SearchProducts(ctx, query, limit, offset)
}

func (s *ProductService) Detail(ctx context.Context, id string) (ProductDetail, error) {
	product, err := s.store.ProductByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return ProductDetail{}, httpx.ErrNotFound
	}
	if err != nil {
		return ProductDetail{}, err
	}
	reviews, _, err := s.store.ListReviews(ctx, id, "most_helpful", 5, 0)
	if err != nil {
		return ProductDetail{}, err
	}
	related, err := s.store.RelatedProducts(ctx, product, 8)
	if err != nil {
		return ProductDetail{}, err
	}
	highRated, _, _ := s.store.ListReviews(ctx, id, "highest_rating", 12, 0)
	lowRated, _, _ := s.store.ListReviews(ctx, id, "lowest_rating", 12, 0)
	positive := filterReviewsByRating(highRated, 4, 5, 3)
	critical := filterReviewsByRating(lowRated, 1, 2, 3)
	return ProductDetail{Product: product, TopReviews: reviews, RelatedProducts: related, PositiveReviews: positive, CriticalReviews: critical}, nil
}

func filterReviewsByRating(reviews []models.Review, minRating, maxRating, limit int) []models.Review {
	filtered := make([]models.Review, 0, limit)
	for _, review := range reviews {
		if review.Rating < minRating || review.Rating > maxRating {
			continue
		}
		filtered = append(filtered, review)
		if len(filtered) == limit {
			return filtered
		}
	}
	return filtered
}

func (s *ProductService) Suggest(ctx context.Context, userID string, req dto.ProductSuggestionRequest) error {
	return s.store.SuggestProduct(ctx, userID, req)
}

func (s *ProductService) Moderate(ctx context.Context, productID string, req dto.ProductModerationRequest) error {
	err := s.store.ModerateProduct(ctx, productID, req)
	if errors.Is(err, sql.ErrNoRows) {
		return httpx.ErrNotFound
	}
	return err
}

func (s *ProductService) BrandAnnouncement(ctx context.Context, userID, brandID string, req dto.BrandAnnouncementRequest) error {
	err := s.store.CreateBrandAnnouncement(ctx, userID, brandID, req)
	if errors.Is(err, sql.ErrNoRows) {
		return httpx.ErrForbidden
	}
	return err
}

func (s *ProductService) ProductUpdate(ctx context.Context, userID, productID string, req dto.ProductUpdateRequest) error {
	err := s.store.CreateProductUpdate(ctx, userID, productID, req)
	if errors.Is(err, sql.ErrNoRows) {
		return httpx.ErrForbidden
	}
	return err
}
