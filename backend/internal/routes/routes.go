package routes

import (
	"log/slog"

	"kinly/backend/internal/config"
	"kinly/backend/internal/handlers"
	"kinly/backend/internal/middleware"
	"kinly/backend/internal/services"

	"github.com/gin-gonic/gin"
)

type Dependencies struct {
	Config      config.Config
	Logger      *slog.Logger
	Handlers    *handlers.Handler
	AuthService *services.AuthService
}

func New(deps Dependencies) *gin.Engine {
	if deps.Config.Env != "local" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(middleware.Recovery(deps.Logger))
	router.Use(middleware.RequestLogger(deps.Logger))
	router.Use(middleware.CORS(deps.Config))

	h := deps.Handlers
	auth := middleware.Auth(deps.AuthService)

	router.GET("/health", h.Health)

	router.POST("/signup", h.Signup)
	router.POST("/login", h.Login)
	router.POST("/logout", auth, h.Logout)

	router.GET("/products", h.ListProducts)
	router.GET("/products/search", h.SearchProducts)
	router.GET("/products/:id", h.ProductDetail)
	router.POST("/reviews", auth, h.CreateReview)
	router.GET("/products/:id/reviews", h.ProductReviews)
	router.DELETE("/reviews/:id", auth, h.DeleteReview)
	router.POST("/reviews/:id/helpful", auth, h.MarkReviewHelpful)
	router.POST("/reviews/:id/comments", auth, h.ReviewComment)

	router.POST("/posts", auth, h.CreatePost)
	router.GET("/posts", h.ListPosts)
	router.GET("/posts/:id", h.PostDetail)
	router.POST("/posts/:id/vote", auth, h.VotePost)
	router.POST("/posts/:id/report", auth, h.ReportPost)
	router.POST("/comments", auth, h.CreateComment)
	router.DELETE("/comments/:id", auth, h.DeleteComment)

	router.GET("/notifications", auth, h.Notifications)
	router.PATCH("/notifications/:id/read", auth, h.MarkNotificationRead)

	router.GET("/users/:id", h.UserProfile)
	router.PATCH("/users/profile", auth, h.UpdateProfile)

	return router
}
