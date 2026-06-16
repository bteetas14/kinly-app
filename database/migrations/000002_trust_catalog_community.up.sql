ALTER TABLE brands
  ADD COLUMN IF NOT EXISTS certification_status TEXT NOT NULL DEFAULT 'unverified',
  ADD COLUMN IF NOT EXISTS joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS violations_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS disputes_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS catalog_status TEXT NOT NULL DEFAULT 'approved',
  ADD COLUMN IF NOT EXISTS moderation_notes TEXT NOT NULL DEFAULT '';

ALTER TABLE reviews
  ADD COLUMN IF NOT EXISTS purchase_type TEXT NOT NULL DEFAULT 'bought_myself',
  ADD COLUMN IF NOT EXISTS skin_type TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS hair_type TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS skin_concerns TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS age_group TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS follow_ups_completed INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS confidence TEXT NOT NULL DEFAULT 'medium',
  ADD COLUMN IF NOT EXISTS confidence_score INTEGER NOT NULL DEFAULT 50,
  ADD COLUMN IF NOT EXISTS weighted_rating NUMERIC(4,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'published',
  ADD COLUMN IF NOT EXISTS report_count INTEGER NOT NULL DEFAULT 0;

UPDATE reviews
SET weighted_rating = rating
WHERE weighted_rating = 0;

CREATE TABLE IF NOT EXISTS review_followups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stage TEXT NOT NULL CHECK (stage IN ('day_1', 'day_30', 'day_90', 'day_180')),
  body TEXT NOT NULL,
  still_using BOOLEAN NOT NULL DEFAULT false,
  would_buy_again BOOLEAN NOT NULL DEFAULT false,
  repurchased BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (review_id, stage)
);

CREATE TABLE IF NOT EXISTS review_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN ('fake_review', 'hidden_sponsorship', 'affiliate_spam', 'suspicious_behavior', 'other')),
  details TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (review_id, reporter_id)
);

CREATE TABLE IF NOT EXISTS wishlisted_products (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

CREATE TABLE IF NOT EXISTS favorite_brands (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, brand_id)
);

CREATE TABLE IF NOT EXISTS user_expertise (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expertise TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, expertise)
);

CREATE TABLE IF NOT EXISTS brand_announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  suggested_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  brand_name TEXT NOT NULL,
  product_name TEXT NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  notes TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_reviews_confidence ON reviews(confidence);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);
CREATE INDEX IF NOT EXISTS idx_review_reports_review_id ON review_reports(review_id);
CREATE INDEX IF NOT EXISTS idx_review_followups_review_id ON review_followups(review_id);
CREATE INDEX IF NOT EXISTS idx_wishlisted_products_user_id ON wishlisted_products(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_brands_user_id ON favorite_brands(user_id);
CREATE INDEX IF NOT EXISTS idx_brand_announcements_brand_id ON brand_announcements(brand_id);
CREATE INDEX IF NOT EXISTS idx_product_updates_brand_id ON product_updates(brand_id);
CREATE INDEX IF NOT EXISTS idx_product_suggestions_status ON product_suggestions(status);
