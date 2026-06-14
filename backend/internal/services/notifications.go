package services

import (
	"context"
	"database/sql"
	"errors"

	"kinly/backend/internal/httpx"
	"kinly/backend/internal/models"
	"kinly/backend/internal/repositories"
)

type NotificationService struct {
	store *repositories.Store
}

func NewNotificationService(store *repositories.Store) *NotificationService {
	return &NotificationService{store: store}
}

func (s *NotificationService) List(ctx context.Context, userID string, limit, offset int) ([]models.Notification, int64, error) {
	return s.store.Notifications(ctx, userID, limit, offset)
}

func (s *NotificationService) MarkRead(ctx context.Context, userID, notificationID string) error {
	err := s.store.MarkNotificationRead(ctx, userID, notificationID)
	if errors.Is(err, sql.ErrNoRows) {
		return httpx.ErrNotFound
	}
	return err
}
