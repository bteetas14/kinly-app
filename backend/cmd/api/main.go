package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"kinly/backend/internal/config"
	"kinly/backend/internal/database"
	"kinly/backend/internal/handlers"
	"kinly/backend/internal/repositories"
	"kinly/backend/internal/routes"
	"kinly/backend/internal/services"
)

func main() {
	cfg := config.Load()
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: cfg.LogLevel()}))
	if err := cfg.Validate(); err != nil {
		logger.Error("invalid configuration", "error", err)
		os.Exit(1)
	}

	db, err := database.Open(cfg.DatabaseURL)
	if err != nil {
		logger.Error("open database", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		logger.Error("ping database", "error", err)
		os.Exit(1)
	}

	store := repositories.NewStore(db)
	authSvc := services.NewAuthService(store, cfg.JWTSecret, cfg.JWTIssuer, cfg.JWTTTL)
	productSvc := services.NewProductService(store)
	reviewSvc := services.NewReviewService(store)
	communitySvc := services.NewCommunityService(store)
	userSvc := services.NewUserService(store)
	notificationSvc := services.NewNotificationService(store)

	h := handlers.New(handlers.Dependencies{
		Auth:          authSvc,
		Products:      productSvc,
		Reviews:       reviewSvc,
		Community:     communitySvc,
		Users:         userSvc,
		Notifications: notificationSvc,
	})

	router := routes.New(routes.Dependencies{
		Config:      cfg,
		Logger:      logger,
		Handlers:    h,
		AuthService: authSvc,
	})

	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
	}
	serverErrors := make(chan error, 1)
	go func() {
		logger.Info("api listening", "port", cfg.Port)
		serverErrors <- server.ListenAndServe()
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		if !errors.Is(err, http.ErrServerClosed) {
			logger.Error("server stopped", "error", err)
			os.Exit(1)
		}
	case sig := <-shutdown:
		logger.Info("shutdown requested", "signal", sig.String())
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := server.Shutdown(ctx); err != nil {
			logger.Error("server shutdown", "error", err)
			os.Exit(1)
		}
	}
}
