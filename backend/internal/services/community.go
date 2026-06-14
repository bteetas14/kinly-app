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

type CommunityService struct {
	store *repositories.Store
}

func NewCommunityService(store *repositories.Store) *CommunityService {
	return &CommunityService{store: store}
}

func (s *CommunityService) CreatePost(ctx context.Context, userID string, req dto.CreatePostRequest) (models.Post, error) {
	return s.store.CreatePost(ctx, userID, req)
}

func (s *CommunityService) ListPosts(ctx context.Context, communityID, query string, limit, offset int) ([]models.Post, int64, error) {
	return s.store.ListPosts(ctx, communityID, query, limit, offset)
}

func (s *CommunityService) Post(ctx context.Context, id string) (models.Post, error) {
	post, err := s.store.PostByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return models.Post{}, httpx.ErrNotFound
	}
	return post, err
}

func (s *CommunityService) CreateComment(ctx context.Context, userID string, req dto.CreateCommentRequest) (models.Comment, error) {
	return s.store.CreateComment(ctx, userID, req)
}

func (s *CommunityService) DeleteComment(ctx context.Context, userID, commentID string) error {
	err := s.store.DeleteComment(ctx, userID, commentID)
	if errors.Is(err, sql.ErrNoRows) {
		return httpx.ErrNotFound
	}
	return err
}

func (s *CommunityService) VotePost(ctx context.Context, userID, postID string, value int) error {
	return s.store.VotePost(ctx, userID, postID, value)
}

func (s *CommunityService) ReportPost(ctx context.Context, userID, postID, reason string) error {
	return s.store.ReportPost(ctx, userID, postID, reason)
}
