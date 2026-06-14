package dto

type SignupRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Username string `json:"username" binding:"required,min=3,max=40"`
	Password string `json:"password" binding:"required,min=8"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type AuthResponse struct {
	Token string      `json:"token"`
	User  UserProfile `json:"user"`
}

type UserProfile struct {
	ID                   string   `json:"id"`
	Email                string   `json:"email,omitempty"`
	Username             string   `json:"username"`
	Role                 string   `json:"role"`
	AvatarURL            string   `json:"avatar_url"`
	Bio                  string   `json:"bio"`
	Reputation           int      `json:"reputation"`
	TrustScore           int      `json:"trust_score"`
	Badges               []string `json:"badges"`
	ReviewCount          int      `json:"review_count"`
	HelpfulVotesReceived int      `json:"helpful_votes_received"`
	FollowersCount       int      `json:"followers_count"`
	FollowingCount       int      `json:"following_count"`
	SavedProducts        []string `json:"saved_products"`
	FavoriteBrands       []string `json:"favorite_brands"`
}

type UpdateProfileRequest struct {
	AvatarURL string `json:"avatar_url"`
	Bio       string `json:"bio" binding:"max=500"`
}

type ProductFilters struct {
	Query         string
	Sort          string
	Brand         string
	MinPrice      *int
	MaxPrice      *int
	SkinType      string
	SensitiveSkin *bool
	CrueltyFree   *bool
	FragranceFree *bool
	Vegan         *bool
}

type ProductDetail struct {
	Product         any   `json:"product"`
	TopReviews      any   `json:"top_reviews"`
	RelatedProducts any   `json:"related_products"`
	ProsSummary     []any `json:"pros_summary,omitempty"`
	ConsSummary     []any `json:"cons_summary,omitempty"`
}

type CreateReviewRequest struct {
	ProductID        string   `json:"product_id" binding:"required,uuid"`
	Rating           int      `json:"rating" binding:"required,min=1,max=5"`
	Title            string   `json:"title" binding:"required,min=3,max=120"`
	Body             string   `json:"body" binding:"required,min=10"`
	Pros             []string `json:"pros"`
	Cons             []string `json:"cons"`
	WouldBuyAgain    bool     `json:"would_buy_again"`
	Repurchased      bool     `json:"repurchased"`
	VerifiedPurchase bool     `json:"verified_purchase"`
	Photos           []string `json:"photos"`
}

type ReviewCommentRequest struct {
	Body string `json:"body" binding:"required,min=1,max=2000"`
}

type CreatePostRequest struct {
	CommunityID string   `json:"community_id" binding:"required,uuid"`
	Title       string   `json:"title" binding:"required,min=3,max=180"`
	Body        string   `json:"body" binding:"required,min=1"`
	Tags        []string `json:"tags"`
	Images      []string `json:"images"`
}

type CreateCommentRequest struct {
	PostID          string `json:"post_id" binding:"required,uuid"`
	ParentCommentID string `json:"parent_comment_id"`
	Body            string `json:"body" binding:"required,min=1,max=4000"`
}

type VoteRequest struct {
	Value int `json:"value" binding:"required,oneof=-1 1"`
}

type ReportPostRequest struct {
	Reason string `json:"reason" binding:"required,min=3,max=500"`
}
