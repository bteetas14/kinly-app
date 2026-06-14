package handlers

import (
	"strconv"
	"time"

	"kinly/backend/internal/dto"
	"kinly/backend/internal/httpx"
	"kinly/backend/internal/middleware"
	"kinly/backend/internal/services"
	"kinly/backend/internal/utils"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	auth          *services.AuthService
	products      *services.ProductService
	reviews       *services.ReviewService
	community     *services.CommunityService
	users         *services.UserService
	notifications *services.NotificationService
}

type Dependencies struct {
	Auth          *services.AuthService
	Products      *services.ProductService
	Reviews       *services.ReviewService
	Community     *services.CommunityService
	Users         *services.UserService
	Notifications *services.NotificationService
}

func New(deps Dependencies) *Handler {
	return &Handler{
		auth:          deps.Auth,
		products:      deps.Products,
		reviews:       deps.Reviews,
		community:     deps.Community,
		users:         deps.Users,
		notifications: deps.Notifications,
	}
}

func (h *Handler) Health(c *gin.Context) {
	httpx.OK(c, gin.H{"status": "ok"})
}

func (h *Handler) Signup(c *gin.Context) {
	var req dto.SignupRequest
	if !bind(c, &req) {
		return
	}
	res, err := h.auth.Signup(c.Request.Context(), req)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.Created(c, res)
}

func (h *Handler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if !bind(c, &req) {
		return
	}
	res, err := h.auth.Login(c.Request.Context(), req)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, res)
}

func (h *Handler) Logout(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	expiresAt := time.Now().Add(30 * 24 * time.Hour)
	if err := h.auth.Logout(c.Request.Context(), middleware.CurrentTokenID(c), userID, expiresAt); err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.NoContent(c)
}

func (h *Handler) ListProducts(c *gin.Context) {
	page := utils.ReadPagination(c)
	filters := readProductFilters(c)
	products, total, err := h.products.List(c.Request.Context(), filters, page.PageSize, page.Offset)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, httpx.Page[any]{Data: toAny(products), Page: page.Page, PageSize: page.PageSize, Total: total})
}

func (h *Handler) ProductDetail(c *gin.Context) {
	detail, err := h.products.Detail(c.Request.Context(), c.Param("id"))
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, detail)
}

func (h *Handler) SearchProducts(c *gin.Context) {
	page := utils.ReadPagination(c)
	products, total, err := h.products.Search(c.Request.Context(), c.Query("q"), page.PageSize, page.Offset)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, httpx.Page[any]{Data: toAny(products), Page: page.Page, PageSize: page.PageSize, Total: total})
}

func (h *Handler) CreateReview(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	var req dto.CreateReviewRequest
	if !bind(c, &req) {
		return
	}
	review, err := h.reviews.Create(c.Request.Context(), userID, req)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.Created(c, review)
}

func (h *Handler) ProductReviews(c *gin.Context) {
	page := utils.ReadPagination(c)
	reviews, total, err := h.reviews.List(c.Request.Context(), c.Param("id"), c.DefaultQuery("sort", "most_helpful"), page.PageSize, page.Offset)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, httpx.Page[any]{Data: toAny(reviews), Page: page.Page, PageSize: page.PageSize, Total: total})
}

func (h *Handler) DeleteReview(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	if err := h.reviews.Delete(c.Request.Context(), userID, c.Param("id")); err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.NoContent(c)
}

func (h *Handler) MarkReviewHelpful(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	if err := h.reviews.Helpful(c.Request.Context(), userID, c.Param("id")); err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.NoContent(c)
}

func (h *Handler) ReviewComment(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	var req dto.ReviewCommentRequest
	if !bind(c, &req) {
		return
	}
	if err := h.reviews.Comment(c.Request.Context(), userID, c.Param("id"), req.Body); err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.NoContent(c)
}

func (h *Handler) CreatePost(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	var req dto.CreatePostRequest
	if !bind(c, &req) {
		return
	}
	post, err := h.community.CreatePost(c.Request.Context(), userID, req)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.Created(c, post)
}

func (h *Handler) ListPosts(c *gin.Context) {
	page := utils.ReadPagination(c)
	posts, total, err := h.community.ListPosts(c.Request.Context(), c.Query("community_id"), c.Query("q"), page.PageSize, page.Offset)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, httpx.Page[any]{Data: toAny(posts), Page: page.Page, PageSize: page.PageSize, Total: total})
}

func (h *Handler) PostDetail(c *gin.Context) {
	post, err := h.community.Post(c.Request.Context(), c.Param("id"))
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, post)
}

func (h *Handler) CreateComment(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	var req dto.CreateCommentRequest
	if !bind(c, &req) {
		return
	}
	comment, err := h.community.CreateComment(c.Request.Context(), userID, req)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.Created(c, comment)
}

func (h *Handler) DeleteComment(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	if err := h.community.DeleteComment(c.Request.Context(), userID, c.Param("id")); err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.NoContent(c)
}

func (h *Handler) VotePost(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	var req dto.VoteRequest
	if !bind(c, &req) {
		return
	}
	if err := h.community.VotePost(c.Request.Context(), userID, c.Param("id"), req.Value); err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.NoContent(c)
}

func (h *Handler) ReportPost(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	var req dto.ReportPostRequest
	if !bind(c, &req) {
		return
	}
	if err := h.community.ReportPost(c.Request.Context(), userID, c.Param("id"), req.Reason); err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.NoContent(c)
}

func (h *Handler) Notifications(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	page := utils.ReadPagination(c)
	items, total, err := h.notifications.List(c.Request.Context(), userID, page.PageSize, page.Offset)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, httpx.Page[any]{Data: toAny(items), Page: page.Page, PageSize: page.PageSize, Total: total})
}

func (h *Handler) MarkNotificationRead(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	if err := h.notifications.MarkRead(c.Request.Context(), userID, c.Param("id")); err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.NoContent(c)
}

func (h *Handler) UserProfile(c *gin.Context) {
	profile, err := h.users.Profile(c.Request.Context(), c.Param("id"))
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, profile)
}

func (h *Handler) UpdateProfile(c *gin.Context) {
	userID, ok := middleware.MustUserID(c)
	if !ok {
		return
	}
	var req dto.UpdateProfileRequest
	if !bind(c, &req) {
		return
	}
	profile, err := h.users.UpdateProfile(c.Request.Context(), userID, req)
	if err != nil {
		httpx.Fail(c, err)
		return
	}
	httpx.OK(c, profile)
}

func bind(c *gin.Context, target any) bool {
	if err := c.ShouldBindJSON(target); err != nil {
		httpx.Validation(c, map[string]string{"body": err.Error()})
		return false
	}
	return true
}

func readProductFilters(c *gin.Context) dto.ProductFilters {
	return dto.ProductFilters{
		Query:         c.Query("q"),
		Sort:          c.DefaultQuery("sort", "trending"),
		Brand:         c.Query("brand"),
		MinPrice:      optionalInt(c.Query("min_price")),
		MaxPrice:      optionalInt(c.Query("max_price")),
		SkinType:      c.Query("skin_type"),
		SensitiveSkin: optionalBool(c.Query("sensitive_skin")),
		CrueltyFree:   optionalBool(c.Query("cruelty_free")),
		FragranceFree: optionalBool(c.Query("fragrance_free")),
		Vegan:         optionalBool(c.Query("vegan")),
	}
}

func optionalInt(raw string) *int {
	if raw == "" {
		return nil
	}
	value, err := strconv.Atoi(raw)
	if err != nil {
		return nil
	}
	return &value
}

func optionalBool(raw string) *bool {
	if raw == "" {
		return nil
	}
	value, err := strconv.ParseBool(raw)
	if err != nil {
		return nil
	}
	return &value
}

func toAny[T any](items []T) []any {
	out := make([]any, 0, len(items))
	for _, item := range items {
		out = append(out, item)
	}
	return out
}
