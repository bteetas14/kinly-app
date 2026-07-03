package models

import "time"

type User struct {
	ID                   string    `json:"id"`
	Email                string    `json:"email"`
	Username             string    `json:"username"`
	Role                 string    `json:"role"`
	AvatarURL            string    `json:"avatar_url"`
	Bio                  string    `json:"bio"`
	Reputation           int       `json:"reputation"`
	TrustScore           int       `json:"trust_score"`
	HelpfulVotesReceived int       `json:"helpful_votes_received"`
	CreatedAt            time.Time `json:"created_at"`
}

type Product struct {
	ID              string    `json:"id"`
	BrandID         string    `json:"brand_id"`
	BrandName       string    `json:"brand_name"`
	CategoryID      string    `json:"category_id"`
	CategoryName    string    `json:"category_name"`
	SubcategoryID   string    `json:"subcategory_id"`
	SubcategoryName string    `json:"subcategory_name"`
	Name            string    `json:"name"`
	Description     string    `json:"description"`
	PriceCents      int       `json:"price_cents"`
	Currency        string    `json:"currency"`
	ImageURLs       []string  `json:"image_urls"`
	SkinTypes       []string  `json:"skin_types"`
	SensitiveSkin   bool      `json:"sensitive_skin"`
	CrueltyFree     bool      `json:"cruelty_free"`
	FragranceFree   bool      `json:"fragrance_free"`
	Vegan           bool      `json:"vegan"`
	CommunityScore  float64   `json:"community_score"`
	TrustScore      float64   `json:"trust_score"`
	RepurchaseRate  float64   `json:"repurchase_rate"`
	VerifiedPercent float64   `json:"verified_purchase_percentage"`
	LongTermPercent float64   `json:"long_term_review_percentage"`
	ReviewCount     int       `json:"review_count"`
	TrendingScore   float64   `json:"trending_score"`
	ProsSummary     []string  `json:"pros_summary"`
	ConsSummary     []string  `json:"cons_summary"`
	CreatedAt       time.Time `json:"created_at"`
}

type Category struct {
	ID            string     `json:"id"`
	Name          string     `json:"name"`
	Slug          string     `json:"slug"`
	Subcategories []Category `json:"subcategories,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
}

type Brand struct {
	ID                  string    `json:"id"`
	Name                string    `json:"name"`
	Description         string    `json:"description"`
	WebsiteURL          string    `json:"website_url"`
	LogoURL             string    `json:"logo_url"`
	BannerURL           string    `json:"banner_url"`
	CategoryNames       []string  `json:"category_names"`
	CategorySlugs       []string  `json:"category_slugs"`
	CertificationStatus string    `json:"certification_status"`
	JoinedAt            time.Time `json:"joined_at"`
	ViolationsCount     int       `json:"violations_count"`
	DisputesCount       int       `json:"disputes_count"`
	Status              string    `json:"status"`
	ProductCount        int       `json:"product_count"`
	ReviewCount         int       `json:"review_count"`
	AverageRating       float64   `json:"average_rating"`
}

type Review struct {
	ID               string    `json:"id"`
	ProductID        string    `json:"product_id"`
	UserID           string    `json:"user_id"`
	Username         string    `json:"username"`
	Rating           int       `json:"rating"`
	Title            string    `json:"title"`
	Body             string    `json:"body"`
	Pros             []string  `json:"pros"`
	Cons             []string  `json:"cons"`
	WouldBuyAgain    bool      `json:"would_buy_again"`
	Repurchased      bool      `json:"repurchased"`
	VerifiedPurchase bool      `json:"verified_purchase"`
	HelpfulCount     int       `json:"helpful_count"`
	Photos           []string  `json:"photos"`
	PurchaseType     string    `json:"purchase_type"`
	SkinType         string    `json:"skin_type"`
	HairType         string    `json:"hair_type"`
	SkinConcerns     []string  `json:"skin_concerns"`
	AgeGroup         string    `json:"age_group"`
	FollowUps        int       `json:"follow_ups_completed"`
	Confidence       string    `json:"confidence"`
	ConfidenceScore  int       `json:"confidence_score"`
	WeightedRating   float64   `json:"weighted_rating"`
	Status           string    `json:"status"`
	ReportCount      int       `json:"report_count"`
	CreatedAt        time.Time `json:"created_at"`
}

type ReviewFollowup struct {
	ID            string    `json:"id"`
	ReviewID      string    `json:"review_id"`
	UserID        string    `json:"user_id"`
	Stage         string    `json:"stage"`
	Body          string    `json:"body"`
	StillUsing    bool      `json:"still_using"`
	WouldBuyAgain bool      `json:"would_buy_again"`
	Repurchased   bool      `json:"repurchased"`
	CreatedAt     time.Time `json:"created_at"`
}

type Post struct {
	ID            string    `json:"id"`
	CommunityID   string    `json:"community_id"`
	CommunityName string    `json:"community_name"`
	AuthorID      string    `json:"author_id"`
	AuthorName    string    `json:"author_name"`
	Title         string    `json:"title"`
	Body          string    `json:"body"`
	Tags          []string  `json:"tags"`
	Images        []string  `json:"images"`
	Upvotes       int       `json:"upvotes"`
	Downvotes     int       `json:"downvotes"`
	Views         int       `json:"views"`
	CommentCount  int       `json:"comment_count"`
	CreatedAt     time.Time `json:"created_at"`
}

type Comment struct {
	ID              string    `json:"id"`
	PostID          string    `json:"post_id"`
	ParentCommentID string    `json:"parent_comment_id"`
	AuthorID        string    `json:"author_id"`
	AuthorName      string    `json:"author_name"`
	Body            string    `json:"body"`
	CreatedAt       time.Time `json:"created_at"`
}

type Community struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Slug        string    `json:"slug"`
	Description string    `json:"description"`
	PostCount   int       `json:"post_count"`
	CreatedAt   time.Time `json:"created_at"`
}

type Notification struct {
	ID           string     `json:"id"`
	UserID       string     `json:"user_id"`
	ActorID      string     `json:"actor_id"`
	Type         string     `json:"type"`
	Title        string     `json:"title"`
	Body         string     `json:"body"`
	ResourceType string     `json:"resource_type"`
	ResourceID   string     `json:"resource_id"`
	ReadAt       *time.Time `json:"read_at"`
	CreatedAt    time.Time  `json:"created_at"`
}
