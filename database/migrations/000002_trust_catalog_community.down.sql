DROP TABLE IF EXISTS product_suggestions;
DROP TABLE IF EXISTS product_updates;
DROP TABLE IF EXISTS brand_announcements;
DROP TABLE IF EXISTS user_expertise;
DROP TABLE IF EXISTS favorite_brands;
DROP TABLE IF EXISTS wishlisted_products;
DROP TABLE IF EXISTS review_reports;
DROP TABLE IF EXISTS review_followups;

ALTER TABLE reviews
  DROP COLUMN IF EXISTS purchase_type,
  DROP COLUMN IF EXISTS skin_type,
  DROP COLUMN IF EXISTS hair_type,
  DROP COLUMN IF EXISTS skin_concerns,
  DROP COLUMN IF EXISTS age_group,
  DROP COLUMN IF EXISTS follow_ups_completed,
  DROP COLUMN IF EXISTS confidence,
  DROP COLUMN IF EXISTS confidence_score,
  DROP COLUMN IF EXISTS weighted_rating,
  DROP COLUMN IF EXISTS status,
  DROP COLUMN IF EXISTS report_count;

ALTER TABLE products
  DROP COLUMN IF EXISTS catalog_status,
  DROP COLUMN IF EXISTS moderation_notes;

ALTER TABLE brands
  DROP COLUMN IF EXISTS certification_status,
  DROP COLUMN IF EXISTS joined_at,
  DROP COLUMN IF EXISTS violations_count,
  DROP COLUMN IF EXISTS disputes_count,
  DROP COLUMN IF EXISTS status;
