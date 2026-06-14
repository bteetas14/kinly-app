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
}

func NewProductService(store *repositories.Store) *ProductService {
	return &ProductService{store: store}
}

func (s *ProductService) List(ctx context.Context, filters dto.ProductFilters, limit, offset int) ([]models.Product, int64, error) {
	return s.store.ListProducts(ctx, filters, limit, offset)
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
	return ProductDetail{Product: product, TopReviews: reviews, RelatedProducts: related}, nil
}
