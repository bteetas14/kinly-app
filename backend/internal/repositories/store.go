package repositories

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"kinly/backend/internal/dto"
	"kinly/backend/internal/models"
)

type Store struct {
	db *sql.DB
}

type UserWithPassword struct {
	models.User
	PasswordHash string
}

func NewStore(db *sql.DB) *Store {
	return &Store{db: db}
}

func (s *Store) DB() *sql.DB {
	return s.db
}

func (s *Store) CreateUser(ctx context.Context, email, username, passwordHash string) (models.User, error) {
	var user models.User
	err := s.db.QueryRowContext(ctx, `
		INSERT INTO users (email, username, password_hash)
		VALUES ($1, $2, $3)
		RETURNING id, email, username, role, coalesce(avatar_url, ''), bio, reputation, trust_score, helpful_votes_received, created_at
	`, email, username, passwordHash).Scan(
		&user.ID, &user.Email, &user.Username, &user.Role, &user.AvatarURL, &user.Bio,
		&user.Reputation, &user.TrustScore, &user.HelpfulVotesReceived, &user.CreatedAt,
	)
	return user, err
}

func (s *Store) UserByEmail(ctx context.Context, email string) (UserWithPassword, error) {
	var user UserWithPassword
	err := s.db.QueryRowContext(ctx, `
		SELECT id, email, username, role, coalesce(avatar_url, ''), bio, reputation, trust_score,
		       helpful_votes_received, created_at, password_hash
		FROM users
		WHERE email = $1 AND deleted_at IS NULL
	`, email).Scan(
		&user.ID, &user.Email, &user.Username, &user.Role, &user.AvatarURL, &user.Bio,
		&user.Reputation, &user.TrustScore, &user.HelpfulVotesReceived, &user.CreatedAt, &user.PasswordHash,
	)
	return user, err
}

func (s *Store) UserByID(ctx context.Context, id string) (models.User, error) {
	var user models.User
	err := s.db.QueryRowContext(ctx, `
		SELECT id, email, username, role, coalesce(avatar_url, ''), bio, reputation, trust_score,
		       helpful_votes_received, created_at
		FROM users
		WHERE id = $1 AND deleted_at IS NULL
	`, id).Scan(
		&user.ID, &user.Email, &user.Username, &user.Role, &user.AvatarURL, &user.Bio,
		&user.Reputation, &user.TrustScore, &user.HelpfulVotesReceived, &user.CreatedAt,
	)
	return user, err
}

func (s *Store) UpdateProfile(ctx context.Context, userID, avatarURL, bio string) (models.User, error) {
	var user models.User
	err := s.db.QueryRowContext(ctx, `
		UPDATE users
		SET avatar_url = NULLIF($2, ''), bio = $3, updated_at = now()
		WHERE id = $1 AND deleted_at IS NULL
		RETURNING id, email, username, role, coalesce(avatar_url, ''), bio, reputation, trust_score, helpful_votes_received, created_at
	`, userID, avatarURL, bio).Scan(
		&user.ID, &user.Email, &user.Username, &user.Role, &user.AvatarURL, &user.Bio,
		&user.Reputation, &user.TrustScore, &user.HelpfulVotesReceived, &user.CreatedAt,
	)
	return user, err
}

func (s *Store) Profile(ctx context.Context, id string) (dto.UserProfile, error) {
	user, err := s.UserByID(ctx, id)
	if err != nil {
		return dto.UserProfile{}, err
	}
	profile := dto.UserProfile{
		ID:                   user.ID,
		Email:                user.Email,
		Username:             user.Username,
		Role:                 user.Role,
		AvatarURL:            user.AvatarURL,
		Bio:                  user.Bio,
		Reputation:           user.Reputation,
		TrustScore:           user.TrustScore,
		HelpfulVotesReceived: user.HelpfulVotesReceived,
	}
	_ = s.db.QueryRowContext(ctx, `SELECT count(*) FROM reviews WHERE user_id = $1 AND deleted_at IS NULL`, id).Scan(&profile.ReviewCount)
	_ = s.db.QueryRowContext(ctx, `SELECT count(*) FROM followers WHERE following_id = $1`, id).Scan(&profile.FollowersCount)
	_ = s.db.QueryRowContext(ctx, `SELECT count(*) FROM followers WHERE follower_id = $1`, id).Scan(&profile.FollowingCount)
	profile.Badges = s.stringList(ctx, `SELECT b.name FROM badges b JOIN user_badges ub ON ub.badge_id = b.id WHERE ub.user_id = $1 ORDER BY ub.awarded_at DESC`, id)
	profile.SavedProducts = s.stringList(ctx, `SELECT product_id::text FROM saved_products WHERE user_id = $1 ORDER BY created_at DESC`, id)
	profile.Wishlist = s.stringList(ctx, `SELECT product_id::text FROM wishlisted_products WHERE user_id = $1 ORDER BY created_at DESC`, id)
	profile.FavoriteBrands = s.stringList(ctx, `
		SELECT b.name
		FROM favorite_brands fb
		JOIN brands b ON b.id = fb.brand_id
		WHERE fb.user_id = $1
		ORDER BY fb.created_at DESC
	`, id)
	profile.Expertise = s.stringList(ctx, `SELECT expertise FROM user_expertise WHERE user_id = $1 ORDER BY expertise`, id)
	_ = s.db.QueryRowContext(ctx, `
		SELECT coalesce(skin_type, ''), coalesce(hair_type, ''), coalesce(array_to_json(skin_concerns), '[]'::json), coalesce(age_group, '')
		FROM user_attributes
		WHERE user_id = $1
	`, id).Scan(&profile.SkinType, &profile.HairType, jsonScanner(&profile.SkinConcerns), &profile.AgeGroup)
	return profile, nil
}

func (s *Store) UpdateUserAttributes(ctx context.Context, userID, skinType, hairType string, skinConcerns []string, ageGroup string) error {
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO user_attributes (user_id, skin_type, hair_type, skin_concerns, age_group)
		VALUES ($1, $2, $3, $4::text[], $5)
		ON CONFLICT (user_id)
		DO UPDATE SET skin_type = excluded.skin_type,
		              hair_type = excluded.hair_type,
		              skin_concerns = excluded.skin_concerns,
		              age_group = excluded.age_group,
		              updated_at = now()
	`, userID, skinType, hairType, textArray(skinConcerns), ageGroup)
	return err
}

func (s *Store) ReplaceExpertise(ctx context.Context, userID string, expertise []string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.ExecContext(ctx, `DELETE FROM user_expertise WHERE user_id = $1`, userID); err != nil {
		return err
	}
	for _, item := range expertise {
		item = strings.TrimSpace(item)
		if item == "" {
			continue
		}
		if _, err := tx.ExecContext(ctx, `INSERT INTO user_expertise (user_id, expertise) VALUES ($1, $2) ON CONFLICT DO NOTHING`, userID, item); err != nil {
			return err
		}
	}
	return tx.Commit()
}

func (s *Store) RecomputeUserStats(ctx context.Context, userID string) error {
	_, err := s.db.ExecContext(ctx, `
		WITH stats AS (
			SELECT
				u.id,
				coalesce(sum(r.helpful_count), 0)::int AS helpful_votes,
				count(r.id)::int AS review_count,
				coalesce((SELECT count(*) FROM posts p WHERE p.author_id = u.id AND p.deleted_at IS NULL), 0)::int AS posts_count,
				coalesce((SELECT count(*) FROM comments c WHERE c.author_id = u.id AND c.deleted_at IS NULL), 0)::int AS comments_count,
				coalesce(sum(CASE WHEN r.verified_purchase THEN 1 ELSE 0 END), 0)::int AS verified_reviews
			FROM users u
			LEFT JOIN reviews r ON r.user_id = u.id AND r.deleted_at IS NULL
			WHERE u.id = $1
			GROUP BY u.id
		)
		UPDATE users u
		SET helpful_votes_received = stats.helpful_votes,
		    reputation = stats.helpful_votes * 3 + stats.review_count * 5 + stats.posts_count * 2 + stats.comments_count,
		    trust_score = least(100, greatest(0, stats.helpful_votes + stats.verified_reviews * 5 + stats.review_count * 2 - u.spam_penalty * 10 - u.report_count * 5)),
		    updated_at = now()
		FROM stats
		WHERE u.id = stats.id
	`, userID)
	return err
}

func (s *Store) RevokeToken(ctx context.Context, tokenID, userID string, expiresAt time.Time) error {
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO revoked_tokens (token_id, user_id, expires_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (token_id) DO NOTHING
	`, tokenID, userID, expiresAt)
	return err
}

func (s *Store) IsTokenRevoked(ctx context.Context, tokenID string) (bool, error) {
	var exists bool
	err := s.db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM revoked_tokens WHERE token_id = $1 AND expires_at > now())`, tokenID).Scan(&exists)
	return exists, err
}

func (s *Store) Categories(ctx context.Context) ([]models.Category, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, name, slug, created_at
		FROM categories
		ORDER BY name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	categories := []models.Category{}
	for rows.Next() {
		var category models.Category
		if err := rows.Scan(&category.ID, &category.Name, &category.Slug, &category.CreatedAt); err != nil {
			return nil, err
		}
		category.Subcategories, _ = s.subcategories(ctx, category.ID)
		categories = append(categories, category)
	}
	return categories, rows.Err()
}

func (s *Store) subcategories(ctx context.Context, categoryID string) ([]models.Category, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, name, slug, created_at
		FROM subcategories
		WHERE category_id = $1
		ORDER BY name
	`, categoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []models.Category{}
	for rows.Next() {
		var item models.Category
		if err := rows.Scan(&item.ID, &item.Name, &item.Slug, &item.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) Brands(ctx context.Context, limit, offset int) ([]models.Brand, int64, error) {
	var total int64
	if err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM brands`).Scan(&total); err != nil {
		return nil, 0, err
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT b.id, b.name, b.description, coalesce(b.website_url, ''), b.certification_status, b.joined_at,
		       b.violations_count, b.disputes_count, b.status,
		       count(DISTINCT p.id)::int,
		       count(r.id)::int,
		       coalesce(avg(r.weighted_rating), 0)::float
		FROM brands b
		LEFT JOIN products p ON p.brand_id = b.id AND p.deleted_at IS NULL
		LEFT JOIN reviews r ON r.product_id = p.id AND r.deleted_at IS NULL AND r.status = 'published'
		GROUP BY b.id
		ORDER BY count(r.id) DESC, b.name
		LIMIT $1 OFFSET $2
	`, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	brands, err := scanBrands(rows)
	return brands, total, err
}

func (s *Store) BrandByID(ctx context.Context, id string) (models.Brand, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT b.id, b.name, b.description, coalesce(b.website_url, ''), b.certification_status, b.joined_at,
		       b.violations_count, b.disputes_count, b.status,
		       count(DISTINCT p.id)::int,
		       count(r.id)::int,
		       coalesce(avg(r.weighted_rating), 0)::float
		FROM brands b
		LEFT JOIN products p ON p.brand_id = b.id AND p.deleted_at IS NULL
		LEFT JOIN reviews r ON r.product_id = p.id AND r.deleted_at IS NULL AND r.status = 'published'
		WHERE b.id = $1
		GROUP BY b.id
	`, id)
	if err != nil {
		return models.Brand{}, err
	}
	defer rows.Close()
	brands, err := scanBrands(rows)
	if err != nil {
		return models.Brand{}, err
	}
	if len(brands) == 0 {
		return models.Brand{}, sql.ErrNoRows
	}
	return brands[0], nil
}

func (s *Store) ListProducts(ctx context.Context, filters dto.ProductFilters, limit, offset int) ([]models.Product, int64, error) {
	where, args := productWhere(filters)
	order := productOrder(filters.Sort)
	countSQL := `SELECT count(*) FROM products p JOIN brands b ON b.id = p.brand_id JOIN categories c ON c.id = p.category_id LEFT JOIN subcategories sc ON sc.id = p.subcategory_id ` + where
	var total int64
	if err := s.db.QueryRowContext(ctx, countSQL, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	args = append(args, limit, offset)
	query := `
		SELECT p.id, p.brand_id, b.name, p.category_id, c.name, coalesce(p.subcategory_id::text, ''), coalesce(sc.name, ''),
		       p.name, p.description, p.price_cents, p.currency, array_to_json(p.image_urls), array_to_json(p.skin_types),
		       p.sensitive_skin, p.cruelty_free, p.fragrance_free, p.vegan,
		       coalesce(avg(r.weighted_rating), avg(r.rating), 0)::float,
		       coalesce(avg(r.confidence_score), 0)::float,
		       coalesce(avg(CASE WHEN r.repurchased THEN 1.0 ELSE 0.0 END), 0)::float,
		       coalesce(avg(CASE WHEN r.verified_purchase THEN 1.0 ELSE 0.0 END), 0)::float,
		       coalesce(avg(CASE WHEN r.follow_ups_completed >= 2 THEN 1.0 ELSE 0.0 END), 0)::float,
		       count(r.id)::int, p.trending_score::float, p.created_at
		FROM products p
		JOIN brands b ON b.id = p.brand_id
		JOIN categories c ON c.id = p.category_id
		LEFT JOIN subcategories sc ON sc.id = p.subcategory_id
		LEFT JOIN reviews r ON r.product_id = p.id AND r.deleted_at IS NULL
	` + where + `
		GROUP BY p.id, b.name, c.name, sc.name
	` + order + ` LIMIT $` + strconv.Itoa(len(args)-1) + ` OFFSET $` + strconv.Itoa(len(args))

	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	products, _, err := scanProducts(rows)
	return products, total, err
}

func (s *Store) ProductByID(ctx context.Context, id string) (models.Product, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT p.id, p.brand_id, b.name, p.category_id, c.name, coalesce(p.subcategory_id::text, ''), coalesce(sc.name, ''),
		       p.name, p.description, p.price_cents, p.currency, array_to_json(p.image_urls), array_to_json(p.skin_types),
		       p.sensitive_skin, p.cruelty_free, p.fragrance_free, p.vegan,
		       coalesce(avg(r.weighted_rating), avg(r.rating), 0)::float,
		       coalesce(avg(r.confidence_score), 0)::float,
		       coalesce(avg(CASE WHEN r.repurchased THEN 1.0 ELSE 0.0 END), 0)::float,
		       coalesce(avg(CASE WHEN r.verified_purchase THEN 1.0 ELSE 0.0 END), 0)::float,
		       coalesce(avg(CASE WHEN r.follow_ups_completed >= 2 THEN 1.0 ELSE 0.0 END), 0)::float,
		       count(r.id)::int, p.trending_score::float, p.created_at
		FROM products p
		JOIN brands b ON b.id = p.brand_id
		JOIN categories c ON c.id = p.category_id
		LEFT JOIN subcategories sc ON sc.id = p.subcategory_id
		LEFT JOIN reviews r ON r.product_id = p.id AND r.deleted_at IS NULL
		WHERE p.id = $1 AND p.deleted_at IS NULL
		GROUP BY p.id, b.name, c.name, sc.name
	`, id)
	if err != nil {
		return models.Product{}, err
	}
	defer rows.Close()
	products, _, err := scanProducts(rows)
	if err != nil {
		return models.Product{}, err
	}
	if len(products) == 0 {
		return models.Product{}, sql.ErrNoRows
	}
	product := products[0]
	product.ProsSummary = s.stringList(ctx, `SELECT unnest(pros) FROM reviews WHERE product_id = $1 AND deleted_at IS NULL GROUP BY 1 ORDER BY count(*) DESC LIMIT 5`, id)
	product.ConsSummary = s.stringList(ctx, `SELECT unnest(cons) FROM reviews WHERE product_id = $1 AND deleted_at IS NULL GROUP BY 1 ORDER BY count(*) DESC LIMIT 5`, id)
	return product, nil
}

func (s *Store) SearchProducts(ctx context.Context, query string, limit, offset int) ([]models.Product, int64, error) {
	filters := dto.ProductFilters{Query: query, Sort: "trending"}
	return s.ListProducts(ctx, filters, limit, offset)
}

func (s *Store) UserOwnsProductBrand(ctx context.Context, userID, productID string) (bool, error) {
	var owns bool
	err := s.db.QueryRowContext(ctx, `
		SELECT EXISTS(
			SELECT 1
			FROM products p
			JOIN brands b ON b.id = p.brand_id
			WHERE p.id = $1 AND b.owner_user_id = $2
		)
	`, productID, userID).Scan(&owns)
	return owns, err
}

func (s *Store) RelatedProducts(ctx context.Context, product models.Product, limit int) ([]models.Product, error) {
	filters := dto.ProductFilters{Sort: "highest_rated"}
	where, args := productWhere(filters)
	args = append(args, product.CategoryID, product.ID, limit)
	query := `
		SELECT p.id, p.brand_id, b.name, p.category_id, c.name, coalesce(p.subcategory_id::text, ''), coalesce(sc.name, ''),
		       p.name, p.description, p.price_cents, p.currency, array_to_json(p.image_urls), array_to_json(p.skin_types),
		       p.sensitive_skin, p.cruelty_free, p.fragrance_free, p.vegan,
		       coalesce(avg(r.weighted_rating), avg(r.rating), 0)::float,
		       coalesce(avg(r.confidence_score), 0)::float,
		       coalesce(avg(CASE WHEN r.repurchased THEN 1.0 ELSE 0.0 END), 0)::float,
		       coalesce(avg(CASE WHEN r.verified_purchase THEN 1.0 ELSE 0.0 END), 0)::float,
		       coalesce(avg(CASE WHEN r.follow_ups_completed >= 2 THEN 1.0 ELSE 0.0 END), 0)::float,
		       count(r.id)::int, p.trending_score::float, p.created_at
		FROM products p
		JOIN brands b ON b.id = p.brand_id
		JOIN categories c ON c.id = p.category_id
		LEFT JOIN subcategories sc ON sc.id = p.subcategory_id
		LEFT JOIN reviews r ON r.product_id = p.id AND r.deleted_at IS NULL
	` + where + fmt.Sprintf(` AND p.category_id = $%d AND p.id <> $%d
		GROUP BY p.id, b.name, c.name, sc.name
		ORDER BY coalesce(avg(r.rating), 0) DESC
		LIMIT $%d`, len(args)-2, len(args)-1, len(args))
	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	products, _, err := scanProducts(rows)
	return products, err
}

func (s *Store) CreateReview(ctx context.Context, userID string, req dto.CreateReviewRequest) (models.Review, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return models.Review{}, err
	}
	defer tx.Rollback()
	var review models.Review
	purchaseType := normalizePurchaseType(req.PurchaseType)
	confidenceScore, confidence, weightedRating := reviewConfidence(req.Rating, purchaseType, req.VerifiedPurchase, req.Repurchased, 0, 0)
	err = tx.QueryRowContext(ctx, `
		INSERT INTO reviews (
			product_id, user_id, rating, title, body, pros, cons, would_buy_again, repurchased, verified_purchase,
			purchase_type, skin_type, hair_type, skin_concerns, age_group, confidence, confidence_score, weighted_rating
		)
		VALUES ($1, $2, $3, $4, $5, $6::text[], $7::text[], $8, $9, $10, $11, $12, $13, $14::text[], $15, $16, $17, $18)
		RETURNING id, product_id, user_id, rating, title, body, array_to_json(pros), array_to_json(cons),
		          would_buy_again, repurchased, verified_purchase, helpful_count, purchase_type, skin_type,
		          hair_type, array_to_json(skin_concerns), age_group, follow_ups_completed, confidence,
		          confidence_score, weighted_rating::float, status, report_count, created_at
	`, req.ProductID, userID, req.Rating, req.Title, req.Body, textArray(req.Pros), textArray(req.Cons),
		req.WouldBuyAgain, req.Repurchased, req.VerifiedPurchase, purchaseType, req.SkinType, req.HairType,
		textArray(req.SkinConcerns), req.AgeGroup, confidence, confidenceScore, weightedRating).Scan(
		&review.ID, &review.ProductID, &review.UserID, &review.Rating, &review.Title, &review.Body,
		jsonScanner(&review.Pros), jsonScanner(&review.Cons), &review.WouldBuyAgain, &review.Repurchased,
		&review.VerifiedPurchase, &review.HelpfulCount, &review.PurchaseType, &review.SkinType, &review.HairType,
		jsonScanner(&review.SkinConcerns), &review.AgeGroup, &review.FollowUps, &review.Confidence,
		&review.ConfidenceScore, &review.WeightedRating, &review.Status, &review.ReportCount, &review.CreatedAt,
	)
	if err != nil {
		return models.Review{}, err
	}
	for _, photo := range req.Photos {
		if _, err := tx.ExecContext(ctx, `INSERT INTO review_photos (review_id, image_url) VALUES ($1, $2)`, review.ID, photo); err != nil {
			return models.Review{}, err
		}
	}
	if err := tx.Commit(); err != nil {
		return models.Review{}, err
	}
	review.Username = ""
	review.Photos = req.Photos
	return review, s.RecomputeUserStats(ctx, userID)
}

func (s *Store) ListReviews(ctx context.Context, productID, sort string, limit, offset int) ([]models.Review, int64, error) {
	order := reviewOrder(sort)
	var total int64
	if err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM reviews WHERE product_id = $1 AND deleted_at IS NULL`, productID).Scan(&total); err != nil {
		return nil, 0, err
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT r.id, r.product_id, r.user_id, u.username, r.rating, r.title, r.body,
		       array_to_json(r.pros), array_to_json(r.cons), r.would_buy_again, r.repurchased, r.verified_purchase,
		       r.helpful_count, coalesce((SELECT json_agg(image_url) FROM review_photos rp WHERE rp.review_id = r.id), '[]'::json),
		       r.purchase_type, r.skin_type, r.hair_type, array_to_json(r.skin_concerns), r.age_group,
		       r.follow_ups_completed, r.confidence, r.confidence_score, r.weighted_rating::float, r.status, r.report_count, r.created_at
		FROM reviews r
		JOIN users u ON u.id = r.user_id
		WHERE r.product_id = $1 AND r.deleted_at IS NULL AND r.status <> 'removed'
	`+order+` LIMIT $2 OFFSET $3`, productID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	reviews, err := scanReviews(rows)
	return reviews, total, err
}

func (s *Store) DeleteReview(ctx context.Context, userID, reviewID string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE reviews SET deleted_at = now() WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`, reviewID, userID)
	if err != nil {
		return err
	}
	count, _ := res.RowsAffected()
	if count == 0 {
		return sql.ErrNoRows
	}
	return s.RecomputeUserStats(ctx, userID)
}

func (s *Store) MarkReviewHelpful(ctx context.Context, userID, reviewID string) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()
	var authorID string
	if err := tx.QueryRowContext(ctx, `SELECT user_id FROM reviews WHERE id = $1 AND deleted_at IS NULL`, reviewID).Scan(&authorID); err != nil {
		return err
	}
	res, err := tx.ExecContext(ctx, `INSERT INTO review_helpful_votes (review_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, reviewID, userID)
	if err != nil {
		return err
	}
	count, _ := res.RowsAffected()
	if count == 1 {
		if _, err := tx.ExecContext(ctx, `UPDATE reviews SET helpful_count = helpful_count + 1 WHERE id = $1`, reviewID); err != nil {
			return err
		}
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO notifications (user_id, actor_id, type, title, body, resource_type, resource_id)
			VALUES ($1, $2, 'helpful_vote', 'Your review was marked helpful', 'Someone found your review helpful.', 'review', $3)
		`, authorID, userID, reviewID); err != nil {
			return err
		}
	}
	if err := tx.Commit(); err != nil {
		return err
	}
	return s.RecomputeUserStats(ctx, authorID)
}

func (s *Store) AddReviewComment(ctx context.Context, userID, reviewID, body string) error {
	var reviewAuthorID string
	if err := s.db.QueryRowContext(ctx, `SELECT user_id FROM reviews WHERE id = $1 AND deleted_at IS NULL`, reviewID).Scan(&reviewAuthorID); err != nil {
		return err
	}
	_, err := s.db.ExecContext(ctx, `
		WITH inserted AS (
			INSERT INTO review_comments (review_id, author_id, body)
			VALUES ($1, $2, $3)
			RETURNING id
		)
		INSERT INTO notifications (user_id, actor_id, type, title, body, resource_type, resource_id)
		SELECT $4, $2, 'reply', 'New review reply', 'Someone replied to your review.', 'review', $1
		FROM inserted
	`, reviewID, userID, body, reviewAuthorID)
	return err
}

func (s *Store) ReviewProductID(ctx context.Context, reviewID string) (string, error) {
	var productID string
	err := s.db.QueryRowContext(ctx, `SELECT product_id::text FROM reviews WHERE id = $1 AND deleted_at IS NULL`, reviewID).Scan(&productID)
	return productID, err
}

func (s *Store) AddReviewFollowup(ctx context.Context, userID, reviewID string, req dto.ReviewFollowupRequest) (models.ReviewFollowup, error) {
	var followup models.ReviewFollowup
	err := s.db.QueryRowContext(ctx, `
		WITH inserted AS (
			INSERT INTO review_followups (review_id, user_id, stage, body, still_using, would_buy_again, repurchased)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			RETURNING id, review_id, user_id, stage, body, still_using, would_buy_again, repurchased, created_at
		), updated AS (
			UPDATE reviews
			SET follow_ups_completed = (
				SELECT count(*) FROM review_followups WHERE review_id = $1
			),
			repurchased = repurchased OR $7,
			would_buy_again = would_buy_again OR $6
			WHERE id = $1 AND user_id = $2
		)
		SELECT id, review_id, user_id, stage, body, still_using, would_buy_again, repurchased, created_at
		FROM inserted
	`, reviewID, userID, req.Stage, req.Body, req.StillUsing, req.WouldBuyAgain, req.Repurchased).Scan(
		&followup.ID, &followup.ReviewID, &followup.UserID, &followup.Stage, &followup.Body,
		&followup.StillUsing, &followup.WouldBuyAgain, &followup.Repurchased, &followup.CreatedAt,
	)
	if err != nil {
		return models.ReviewFollowup{}, err
	}
	_, _ = s.db.ExecContext(ctx, `
		UPDATE reviews
		SET confidence_score = least(100, confidence_score + 10),
		    confidence = CASE WHEN least(100, confidence_score + 10) >= 75 THEN 'high' WHEN least(100, confidence_score + 10) >= 45 THEN 'medium' ELSE 'low' END,
		    weighted_rating = rating * (least(100, confidence_score + 10)::numeric / 100.0)
		WHERE id = $1
	`, reviewID)
	return followup, nil
}

func (s *Store) ReportReview(ctx context.Context, userID, reviewID string, req dto.ReviewReportRequest) error {
	_, err := s.db.ExecContext(ctx, `
		WITH inserted AS (
			INSERT INTO review_reports (review_id, reporter_id, reason, details)
			VALUES ($1, $2, $3, $4)
			ON CONFLICT DO NOTHING
			RETURNING id
		)
		UPDATE reviews
		SET report_count = report_count + (SELECT count(*) FROM inserted),
		    status = CASE WHEN report_count + (SELECT count(*) FROM inserted) >= 2 THEN 'under_investigation' ELSE status END,
		    confidence_score = greatest(0, confidence_score - ((SELECT count(*) FROM inserted) * 15)),
		    confidence = CASE
		      WHEN greatest(0, confidence_score - ((SELECT count(*) FROM inserted) * 15)) >= 75 THEN 'high'
		      WHEN greatest(0, confidence_score - ((SELECT count(*) FROM inserted) * 15)) >= 45 THEN 'medium'
		      ELSE 'low'
		    END
		WHERE id = $1
	`, reviewID, userID, req.Reason, req.Details)
	return err
}

func (s *Store) Communities(ctx context.Context) ([]models.Community, error) {
	rows, err := s.db.QueryContext(ctx, `
		SELECT c.id, c.name, c.slug, c.description, count(p.id)::int, c.created_at
		FROM communities c
		LEFT JOIN posts p ON p.community_id = c.id AND p.deleted_at IS NULL
		GROUP BY c.id
		ORDER BY c.name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	communities := []models.Community{}
	for rows.Next() {
		var community models.Community
		if err := rows.Scan(&community.ID, &community.Name, &community.Slug, &community.Description, &community.PostCount, &community.CreatedAt); err != nil {
			return nil, err
		}
		communities = append(communities, community)
	}
	return communities, rows.Err()
}

func (s *Store) CommentsForPost(ctx context.Context, postID string, limit, offset int) ([]models.Comment, int64, error) {
	var total int64
	if err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM comments WHERE post_id = $1 AND deleted_at IS NULL`, postID).Scan(&total); err != nil {
		return nil, 0, err
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT c.id, c.post_id, coalesce(c.parent_comment_id::text, ''), c.author_id, u.username, c.body, c.created_at
		FROM comments c
		JOIN users u ON u.id = c.author_id
		WHERE c.post_id = $1 AND c.deleted_at IS NULL
		ORDER BY c.created_at ASC
		LIMIT $2 OFFSET $3
	`, postID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	comments := []models.Comment{}
	for rows.Next() {
		var comment models.Comment
		if err := rows.Scan(&comment.ID, &comment.PostID, &comment.ParentCommentID, &comment.AuthorID, &comment.AuthorName, &comment.Body, &comment.CreatedAt); err != nil {
			return nil, 0, err
		}
		comments = append(comments, comment)
	}
	return comments, total, rows.Err()
}

func (s *Store) CreatePost(ctx context.Context, userID string, req dto.CreatePostRequest) (models.Post, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return models.Post{}, err
	}
	defer tx.Rollback()
	var post models.Post
	err = tx.QueryRowContext(ctx, `
		INSERT INTO posts (community_id, author_id, title, body, tags)
		VALUES ($1, $2, $3, $4, $5::text[])
		RETURNING id, community_id, author_id, title, body, array_to_json(tags), upvotes, downvotes, views, created_at
	`, req.CommunityID, userID, req.Title, req.Body, textArray(req.Tags)).Scan(
		&post.ID, &post.CommunityID, &post.AuthorID, &post.Title, &post.Body, jsonScanner(&post.Tags), &post.Upvotes, &post.Downvotes, &post.Views, &post.CreatedAt,
	)
	if err != nil {
		return models.Post{}, err
	}
	for _, image := range req.Images {
		if _, err := tx.ExecContext(ctx, `INSERT INTO post_images (post_id, image_url) VALUES ($1, $2)`, post.ID, image); err != nil {
			return models.Post{}, err
		}
	}
	if err := tx.Commit(); err != nil {
		return models.Post{}, err
	}
	post.Images = req.Images
	return post, s.RecomputeUserStats(ctx, userID)
}

func (s *Store) ListPosts(ctx context.Context, communityID, query string, limit, offset int) ([]models.Post, int64, error) {
	args := []any{}
	clauses := []string{"p.deleted_at IS NULL", "p.status <> 'removed'"}
	if communityID != "" {
		args = append(args, communityID)
		clauses = append(clauses, fmt.Sprintf("p.community_id = $%d", len(args)))
	}
	if query != "" {
		args = append(args, query)
		clauses = append(clauses, fmt.Sprintf("(p.search_vector @@ plainto_tsquery('english', $%d) OR p.title ILIKE '%%' || $%d || '%%')", len(args), len(args)))
	}
	where := " WHERE " + strings.Join(clauses, " AND ")
	var total int64
	if err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM posts p`+where, args...).Scan(&total); err != nil {
		return nil, 0, err
	}
	args = append(args, limit, offset)
	rows, err := s.db.QueryContext(ctx, `
		SELECT p.id, p.community_id, cm.name, p.author_id, u.username, p.title, p.body, array_to_json(p.tags),
		       coalesce((SELECT json_agg(image_url) FROM post_images pi WHERE pi.post_id = p.id), '[]'::json),
		       p.upvotes, p.downvotes, p.views, coalesce((SELECT count(*) FROM comments c WHERE c.post_id = p.id AND c.deleted_at IS NULL), 0)::int, p.created_at
		FROM posts p
		JOIN users u ON u.id = p.author_id
		JOIN communities cm ON cm.id = p.community_id
	`+where+` ORDER BY (p.upvotes - p.downvotes) DESC, p.created_at DESC LIMIT $`+strconv.Itoa(len(args)-1)+` OFFSET $`+strconv.Itoa(len(args)), args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	posts, err := scanPosts(rows)
	return posts, total, err
}

func (s *Store) PostByID(ctx context.Context, id string) (models.Post, error) {
	_, _ = s.db.ExecContext(ctx, `UPDATE posts SET views = views + 1 WHERE id = $1`, id)
	rows, err := s.db.QueryContext(ctx, `
		SELECT p.id, p.community_id, cm.name, p.author_id, u.username, p.title, p.body, array_to_json(p.tags),
		       coalesce((SELECT json_agg(image_url) FROM post_images pi WHERE pi.post_id = p.id), '[]'::json),
		       p.upvotes, p.downvotes, p.views, coalesce((SELECT count(*) FROM comments c WHERE c.post_id = p.id AND c.deleted_at IS NULL), 0)::int, p.created_at
		FROM posts p
		JOIN users u ON u.id = p.author_id
		JOIN communities cm ON cm.id = p.community_id
		WHERE p.id = $1 AND p.deleted_at IS NULL AND p.status <> 'removed'
	`, id)
	if err != nil {
		return models.Post{}, err
	}
	defer rows.Close()
	posts, err := scanPosts(rows)
	if err != nil {
		return models.Post{}, err
	}
	if len(posts) == 0 {
		return models.Post{}, sql.ErrNoRows
	}
	return posts[0], nil
}

func (s *Store) CreateComment(ctx context.Context, userID string, req dto.CreateCommentRequest) (models.Comment, error) {
	var comment models.Comment
	parent := sql.NullString{String: req.ParentCommentID, Valid: req.ParentCommentID != ""}
	err := s.db.QueryRowContext(ctx, `
		INSERT INTO comments (post_id, parent_comment_id, author_id, body)
		VALUES ($1, $2, $3, $4)
		RETURNING id, post_id, coalesce(parent_comment_id::text, ''), author_id, body, created_at
	`, req.PostID, parent, userID, req.Body).Scan(&comment.ID, &comment.PostID, &comment.ParentCommentID, &comment.AuthorID, &comment.Body, &comment.CreatedAt)
	if err != nil {
		return models.Comment{}, err
	}
	var postAuthorID string
	_ = s.db.QueryRowContext(ctx, `SELECT author_id FROM posts WHERE id = $1`, req.PostID).Scan(&postAuthorID)
	if postAuthorID != "" && postAuthorID != userID {
		_, _ = s.db.ExecContext(ctx, `
			INSERT INTO notifications (user_id, actor_id, type, title, body, resource_type, resource_id)
			VALUES ($1, $2, 'reply', 'New post reply', 'Someone replied to your post.', 'post', $3)
		`, postAuthorID, userID, req.PostID)
	}
	return comment, s.RecomputeUserStats(ctx, userID)
}

func (s *Store) DeleteComment(ctx context.Context, userID, commentID string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE comments SET deleted_at = now() WHERE id = $1 AND author_id = $2 AND deleted_at IS NULL`, commentID, userID)
	if err != nil {
		return err
	}
	count, _ := res.RowsAffected()
	if count == 0 {
		return sql.ErrNoRows
	}
	return s.RecomputeUserStats(ctx, userID)
}

func (s *Store) VotePost(ctx context.Context, userID, postID string, value int) error {
	_, err := s.db.ExecContext(ctx, `
		WITH old_vote AS (
			SELECT value FROM post_votes WHERE post_id = $1 AND user_id = $2
		), upserted AS (
			INSERT INTO post_votes (post_id, user_id, value)
			VALUES ($1, $2, $3)
			ON CONFLICT (post_id, user_id)
			DO UPDATE SET value = excluded.value, updated_at = now()
			RETURNING value
		)
		UPDATE posts
		SET upvotes = upvotes + CASE WHEN $3 = 1 THEN 1 ELSE 0 END - CASE WHEN coalesce((SELECT value FROM old_vote), 0) = 1 THEN 1 ELSE 0 END,
		    downvotes = downvotes + CASE WHEN $3 = -1 THEN 1 ELSE 0 END - CASE WHEN coalesce((SELECT value FROM old_vote), 0) = -1 THEN 1 ELSE 0 END
		WHERE id = $1
	`, postID, userID, value)
	return err
}

func (s *Store) ReportPost(ctx context.Context, userID, postID, reason string) error {
	_, err := s.db.ExecContext(ctx, `
		WITH inserted AS (
			INSERT INTO post_reports (post_id, reporter_id, reason)
			VALUES ($1, $2, $3)
			ON CONFLICT DO NOTHING
			RETURNING id
		)
		UPDATE posts
		SET report_count = report_count + (SELECT count(*) FROM inserted),
		    status = CASE WHEN report_count + (SELECT count(*) FROM inserted) >= 3 THEN 'reported' ELSE status END
		WHERE id = $1
	`, postID, userID, reason)
	return err
}

func (s *Store) Notifications(ctx context.Context, userID string, limit, offset int) ([]models.Notification, int64, error) {
	var total int64
	if err := s.db.QueryRowContext(ctx, `SELECT count(*) FROM notifications WHERE user_id = $1`, userID).Scan(&total); err != nil {
		return nil, 0, err
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT id, user_id, coalesce(actor_id::text, ''), type, title, body, coalesce(resource_type, ''), coalesce(resource_id::text, ''), read_at, created_at
		FROM notifications
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	items := []models.Notification{}
	for rows.Next() {
		var n models.Notification
		if err := rows.Scan(&n.ID, &n.UserID, &n.ActorID, &n.Type, &n.Title, &n.Body, &n.ResourceType, &n.ResourceID, &n.ReadAt, &n.CreatedAt); err != nil {
			return nil, 0, err
		}
		items = append(items, n)
	}
	return items, total, rows.Err()
}

func (s *Store) MarkNotificationRead(ctx context.Context, userID, notificationID string) error {
	res, err := s.db.ExecContext(ctx, `UPDATE notifications SET read_at = coalesce(read_at, now()) WHERE id = $1 AND user_id = $2`, notificationID, userID)
	if err != nil {
		return err
	}
	count, _ := res.RowsAffected()
	if count == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (s *Store) SetSavedProduct(ctx context.Context, userID, productID string, saved bool) error {
	if saved {
		_, err := s.db.ExecContext(ctx, `INSERT INTO saved_products (user_id, product_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, userID, productID)
		return err
	}
	_, err := s.db.ExecContext(ctx, `DELETE FROM saved_products WHERE user_id = $1 AND product_id = $2`, userID, productID)
	return err
}

func (s *Store) SetWishlistedProduct(ctx context.Context, userID, productID string, wishlisted bool) error {
	if wishlisted {
		_, err := s.db.ExecContext(ctx, `INSERT INTO wishlisted_products (user_id, product_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, userID, productID)
		return err
	}
	_, err := s.db.ExecContext(ctx, `DELETE FROM wishlisted_products WHERE user_id = $1 AND product_id = $2`, userID, productID)
	return err
}

func (s *Store) SetFavoriteBrand(ctx context.Context, userID, brandID string, favorite bool) error {
	if favorite {
		_, err := s.db.ExecContext(ctx, `INSERT INTO favorite_brands (user_id, brand_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, userID, brandID)
		return err
	}
	_, err := s.db.ExecContext(ctx, `DELETE FROM favorite_brands WHERE user_id = $1 AND brand_id = $2`, userID, brandID)
	return err
}

func (s *Store) SuggestProduct(ctx context.Context, userID string, req dto.ProductSuggestionRequest) error {
	category := sql.NullString{String: req.CategoryID, Valid: req.CategoryID != ""}
	_, err := s.db.ExecContext(ctx, `
		INSERT INTO product_suggestions (suggested_by, brand_name, product_name, category_id, notes)
		VALUES ($1, $2, $3, $4, $5)
	`, userID, req.BrandName, req.ProductName, category, req.Notes)
	return err
}

func (s *Store) ModerateProduct(ctx context.Context, productID string, req dto.ProductModerationRequest) error {
	res, err := s.db.ExecContext(ctx, `
		UPDATE products
		SET catalog_status = $2, moderation_notes = $3, updated_at = now()
		WHERE id = $1 AND deleted_at IS NULL
	`, productID, req.Status, req.Notes)
	if err != nil {
		return err
	}
	count, _ := res.RowsAffected()
	if count == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (s *Store) CreateBrandAnnouncement(ctx context.Context, userID, brandID string, req dto.BrandAnnouncementRequest) error {
	owns, err := s.UserOwnsBrand(ctx, userID, brandID)
	if err != nil {
		return err
	}
	if !owns {
		return sql.ErrNoRows
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO brand_announcements (brand_id, title, body) VALUES ($1, $2, $3)`, brandID, req.Title, req.Body)
	return err
}

func (s *Store) CreateProductUpdate(ctx context.Context, userID, productID string, req dto.ProductUpdateRequest) error {
	var brandID string
	err := s.db.QueryRowContext(ctx, `
		SELECT b.id::text
		FROM products p
		JOIN brands b ON b.id = p.brand_id
		WHERE p.id = $1 AND b.owner_user_id = $2
	`, productID, userID).Scan(&brandID)
	if err != nil {
		return err
	}
	_, err = s.db.ExecContext(ctx, `INSERT INTO product_updates (product_id, brand_id, title, body) VALUES ($1, $2, $3, $4)`, productID, brandID, req.Title, req.Body)
	return err
}

func (s *Store) UserOwnsBrand(ctx context.Context, userID, brandID string) (bool, error) {
	var owns bool
	err := s.db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM brands WHERE id = $1 AND owner_user_id = $2)`, brandID, userID).Scan(&owns)
	return owns, err
}

func (s *Store) stringList(ctx context.Context, query string, args ...any) []string {
	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return []string{}
	}
	defer rows.Close()
	values := []string{}
	for rows.Next() {
		var value string
		if rows.Scan(&value) == nil {
			values = append(values, value)
		}
	}
	return values
}

func productWhere(filters dto.ProductFilters) (string, []any) {
	args := []any{}
	clauses := []string{"p.deleted_at IS NULL"}
	if filters.Query != "" {
		args = append(args, filters.Query)
		clauses = append(clauses, fmt.Sprintf("(p.search_vector @@ plainto_tsquery('english', $%d) OR p.name ILIKE '%%' || $%d || '%%' OR b.name ILIKE '%%' || $%d || '%%' OR c.name ILIKE '%%' || $%d || '%%')", len(args), len(args), len(args), len(args)))
	}
	if filters.Brand != "" {
		args = append(args, filters.Brand)
		clauses = append(clauses, fmt.Sprintf("b.name ILIKE $%d", len(args)))
	}
	if filters.Category != "" {
		args = append(args, filters.Category)
		clauses = append(clauses, fmt.Sprintf("(c.slug = $%d OR c.name ILIKE $%d OR sc.slug = $%d OR sc.name ILIKE $%d)", len(args), len(args), len(args), len(args)))
	}
	if filters.MinPrice != nil {
		args = append(args, *filters.MinPrice)
		clauses = append(clauses, fmt.Sprintf("p.price_cents >= $%d", len(args)))
	}
	if filters.MaxPrice != nil {
		args = append(args, *filters.MaxPrice)
		clauses = append(clauses, fmt.Sprintf("p.price_cents <= $%d", len(args)))
	}
	if filters.SkinType != "" {
		args = append(args, filters.SkinType)
		clauses = append(clauses, fmt.Sprintf("$%d = ANY(p.skin_types)", len(args)))
	}
	if filters.SensitiveSkin != nil {
		args = append(args, *filters.SensitiveSkin)
		clauses = append(clauses, fmt.Sprintf("p.sensitive_skin = $%d", len(args)))
	}
	if filters.CrueltyFree != nil {
		args = append(args, *filters.CrueltyFree)
		clauses = append(clauses, fmt.Sprintf("p.cruelty_free = $%d", len(args)))
	}
	if filters.FragranceFree != nil {
		args = append(args, *filters.FragranceFree)
		clauses = append(clauses, fmt.Sprintf("p.fragrance_free = $%d", len(args)))
	}
	if filters.Vegan != nil {
		args = append(args, *filters.Vegan)
		clauses = append(clauses, fmt.Sprintf("p.vegan = $%d", len(args)))
	}
	return " WHERE " + strings.Join(clauses, " AND "), args
}

func productOrder(sort string) string {
	switch sort {
	case "lowest_rated":
		return " ORDER BY coalesce(avg(r.rating), 0) ASC"
	case "most_reviewed":
		return " ORDER BY count(r.id) DESC"
	case "most_trusted_reviews":
		return " ORDER BY coalesce(avg(r.confidence_score), 0) DESC"
	case "most_repurchased":
		return " ORDER BY coalesce(avg(CASE WHEN r.repurchased THEN 1.0 ELSE 0.0 END), 0) DESC"
	case "lowest_price":
		return " ORDER BY p.price_cents ASC"
	case "highest_price":
		return " ORDER BY p.price_cents DESC"
	case "newest":
		return " ORDER BY p.created_at DESC"
	case "highest_rated":
		return " ORDER BY coalesce(avg(r.weighted_rating), avg(r.rating), 0) DESC"
	case "trending":
		fallthrough
	default:
		return " ORDER BY p.trending_score DESC, count(r.id) DESC"
	}
}

func reviewOrder(sort string) string {
	switch sort {
	case "highest_confidence":
		return " ORDER BY r.confidence_score DESC, r.created_at DESC"
	case "highest_trust_reviewer":
		return " ORDER BY r.confidence_score DESC, r.created_at DESC"
	case "newest":
		return " ORDER BY r.created_at DESC"
	case "highest_rating":
		return " ORDER BY r.rating DESC, r.created_at DESC"
	case "lowest_rating":
		return " ORDER BY r.rating ASC, r.created_at DESC"
	case "most_helpful":
		fallthrough
	default:
		return " ORDER BY r.helpful_count DESC, r.created_at DESC"
	}
}

func scanProducts(rows *sql.Rows) ([]models.Product, int64, error) {
	products := []models.Product{}
	for rows.Next() {
		var p models.Product
		if err := rows.Scan(
			&p.ID, &p.BrandID, &p.BrandName, &p.CategoryID, &p.CategoryName, &p.SubcategoryID, &p.SubcategoryName,
			&p.Name, &p.Description, &p.PriceCents, &p.Currency, jsonScanner(&p.ImageURLs), jsonScanner(&p.SkinTypes),
			&p.SensitiveSkin, &p.CrueltyFree, &p.FragranceFree, &p.Vegan, &p.CommunityScore, &p.TrustScore,
			&p.RepurchaseRate, &p.VerifiedPercent, &p.LongTermPercent, &p.ReviewCount, &p.TrendingScore, &p.CreatedAt,
		); err != nil {
			return nil, 0, err
		}
		products = append(products, p)
	}
	return products, 0, rows.Err()
}

func scanBrands(rows *sql.Rows) ([]models.Brand, error) {
	brands := []models.Brand{}
	for rows.Next() {
		var brand models.Brand
		if err := rows.Scan(
			&brand.ID, &brand.Name, &brand.Description, &brand.WebsiteURL, &brand.CertificationStatus, &brand.JoinedAt,
			&brand.ViolationsCount, &brand.DisputesCount, &brand.Status, &brand.ProductCount, &brand.ReviewCount, &brand.AverageRating,
		); err != nil {
			return nil, err
		}
		brands = append(brands, brand)
	}
	return brands, rows.Err()
}

func scanReviews(rows *sql.Rows) ([]models.Review, error) {
	reviews := []models.Review{}
	for rows.Next() {
		var r models.Review
		if err := rows.Scan(
			&r.ID, &r.ProductID, &r.UserID, &r.Username, &r.Rating, &r.Title, &r.Body,
			jsonScanner(&r.Pros), jsonScanner(&r.Cons), &r.WouldBuyAgain, &r.Repurchased, &r.VerifiedPurchase,
			&r.HelpfulCount, jsonScanner(&r.Photos), &r.PurchaseType, &r.SkinType, &r.HairType,
			jsonScanner(&r.SkinConcerns), &r.AgeGroup, &r.FollowUps, &r.Confidence, &r.ConfidenceScore,
			&r.WeightedRating, &r.Status, &r.ReportCount, &r.CreatedAt,
		); err != nil {
			return nil, err
		}
		reviews = append(reviews, r)
	}
	return reviews, rows.Err()
}

func scanPosts(rows *sql.Rows) ([]models.Post, error) {
	posts := []models.Post{}
	for rows.Next() {
		var p models.Post
		if err := rows.Scan(
			&p.ID, &p.CommunityID, &p.CommunityName, &p.AuthorID, &p.AuthorName, &p.Title, &p.Body,
			jsonScanner(&p.Tags), jsonScanner(&p.Images), &p.Upvotes, &p.Downvotes, &p.Views, &p.CommentCount, &p.CreatedAt,
		); err != nil {
			return nil, err
		}
		posts = append(posts, p)
	}
	return posts, rows.Err()
}

type jsonArrayScanner struct {
	target *[]string
}

func jsonScanner(target *[]string) *jsonArrayScanner {
	return &jsonArrayScanner{target: target}
}

func (s *jsonArrayScanner) Scan(src any) error {
	if src == nil {
		*s.target = []string{}
		return nil
	}
	var data []byte
	switch value := src.(type) {
	case []byte:
		data = value
	case string:
		data = []byte(value)
	default:
		return fmt.Errorf("unsupported json array source %T", src)
	}
	if len(data) == 0 {
		*s.target = []string{}
		return nil
	}
	return json.Unmarshal(data, s.target)
}

func textArray(values []string) string {
	if len(values) == 0 {
		return "{}"
	}
	escaped := make([]string, 0, len(values))
	for _, value := range values {
		value = strings.ReplaceAll(value, `\`, `\\`)
		value = strings.ReplaceAll(value, `"`, `\"`)
		escaped = append(escaped, `"`+value+`"`)
	}
	return "{" + strings.Join(escaped, ",") + "}"
}

func normalizePurchaseType(value string) string {
	switch value {
	case "gifted", "pr_package", "sponsored", "free_sample", "beta_tester":
		return value
	default:
		return "bought_myself"
	}
}

func reviewConfidence(rating int, purchaseType string, verifiedPurchase, repurchased bool, followUps, reports int) (int, string, float64) {
	score := 45
	switch purchaseType {
	case "bought_myself":
		score += 18
	case "gifted", "free_sample", "beta_tester":
		score += 8
	case "pr_package":
		score -= 5
	case "sponsored":
		score -= 15
	}
	if verifiedPurchase {
		score += 12
	}
	if repurchased {
		score += 14
	}
	score += followUps * 10
	score -= reports * 15
	if score < 0 {
		score = 0
	}
	if score > 100 {
		score = 100
	}
	confidence := "low"
	if score >= 75 {
		confidence = "high"
	} else if score >= 45 {
		confidence = "medium"
	}
	weighted := float64(rating) * (float64(score) / 100.0)
	return score, confidence, weighted
}

func NormalizeSQLError(err error) error {
	if errors.Is(err, sql.ErrNoRows) {
		return err
	}
	return err
}
