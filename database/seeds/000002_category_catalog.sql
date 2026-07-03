INSERT INTO brands (name, description, website_url) VALUES
  ('Root Ritual', 'Haircare focused on scalp health and everyday routines.', 'https://example.com/root-ritual'),
  ('Form & Fold', 'Everyday fashion essentials and wardrobe staples.', 'https://example.com/form-and-fold'),
  ('Daily Balance', 'Approachable wellness products for daily routines.', 'https://example.com/daily-balance'),
  ('Dewdrop Studio', 'Hydration-first skincare for simple daily routines.', 'https://example.com/dewdrop-studio'),
  ('Clear Theory', 'Ingredient-led skincare for acne-prone and sensitive skin.', 'https://example.com/clear-theory'),
  ('Curl Kind', 'Moisture-rich care for curls, coils, and textured hair.', 'https://example.com/curl-kind'),
  ('Strand Lab', 'Performance haircare for repair, volume, and scalp balance.', 'https://example.com/strand-lab'),
  ('Muse Color', 'Wearable color cosmetics with expressive finishes.', 'https://example.com/muse-color'),
  ('Bare Edit', 'Minimal everyday makeup with skin-friendly formulas.', 'https://example.com/bare-edit'),
  ('Soft Form', 'Comfort-focused body care for dry and sensitive skin.', 'https://example.com/soft-form'),
  ('Ritual Works', 'Elevated bath and body essentials for daily rituals.', 'https://example.com/ritual-works'),
  ('Core Bloom', 'Nutrition and wellness essentials for active lifestyles.', 'https://example.com/core-bloom'),
  ('Good Habit', 'Simple supplements and functional daily wellness products.', 'https://example.com/good-habit'),
  ('Sunday Studio', 'Relaxed contemporary clothing for everyday wear.', 'https://example.com/sunday-studio'),
  ('Line & Loop', 'Modern footwear and wardrobe essentials.', 'https://example.com/line-and-loop')
ON CONFLICT (name) DO NOTHING;

INSERT INTO products (
  brand_id,
  category_id,
  name,
  description,
  price_cents,
  cruelty_free,
  fragrance_free,
  vegan,
  trending_score
)
SELECT
  b.id,
  c.id,
  'Cloud Body Lotion',
  'A lightweight daily body lotion with a soft, non-sticky finish.',
  1600,
  true,
  true,
  true,
  8.3
FROM brands b, categories c
WHERE b.name = 'Everyday Beauty'
  AND c.slug = 'body-care'
  AND NOT EXISTS (
    SELECT 1 FROM products p
    WHERE p.brand_id = b.id AND p.name = 'Cloud Body Lotion'
  );

INSERT INTO products (
  brand_id,
  category_id,
  name,
  description,
  price_cents,
  cruelty_free,
  fragrance_free,
  vegan,
  trending_score
)
SELECT
  b.id,
  c.id,
  'Soft Tint Lip Balm',
  'A sheer everyday lip tint with a comfortable balm texture.',
  1200,
  true,
  true,
  true,
  8.0
FROM brands b, categories c
WHERE b.name = 'Everyday Beauty'
  AND c.slug = 'makeup'
  AND NOT EXISTS (
    SELECT 1 FROM products p
    WHERE p.brand_id = b.id AND p.name = 'Soft Tint Lip Balm'
  );

INSERT INTO products (
  brand_id,
  category_id,
  subcategory_id,
  name,
  description,
  price_cents,
  cruelty_free,
  fragrance_free,
  vegan,
  trending_score
)
SELECT
  b.id,
  c.id,
  s.id,
  'Daily Scalp Shampoo',
  'A gentle shampoo designed for regular cleansing without stripping.',
  1900,
  true,
  false,
  true,
  8.8
FROM brands b, categories c, subcategories s
WHERE b.name = 'Root Ritual'
  AND c.slug = 'haircare'
  AND s.slug = 'shampoo'
  AND NOT EXISTS (
    SELECT 1 FROM products p
    WHERE p.brand_id = b.id AND p.name = 'Daily Scalp Shampoo'
  );

INSERT INTO products (
  brand_id,
  category_id,
  subcategory_id,
  name,
  description,
  price_cents,
  cruelty_free,
  fragrance_free,
  vegan,
  trending_score
)
SELECT
  b.id,
  c.id,
  s.id,
  'Everyday Ribbed Top',
  'A soft fitted top designed for repeat wear and easy layering.',
  2800,
  false,
  false,
  false,
  7.9
FROM brands b, categories c, subcategories s
WHERE b.name = 'Form & Fold'
  AND c.slug = 'fashion'
  AND s.slug = 'tops'
  AND NOT EXISTS (
    SELECT 1 FROM products p
    WHERE p.brand_id = b.id AND p.name = 'Everyday Ribbed Top'
  );

INSERT INTO products (
  brand_id,
  category_id,
  subcategory_id,
  name,
  description,
  price_cents,
  cruelty_free,
  fragrance_free,
  vegan,
  trending_score
)
SELECT
  b.id,
  c.id,
  s.id,
  'Plant Protein Blend',
  'A simple plant-based protein blend for smoothies and daily nutrition.',
  3200,
  true,
  true,
  true,
  8.1
FROM brands b, categories c, subcategories s
WHERE b.name = 'Daily Balance'
  AND c.slug = 'wellness'
  AND s.slug = 'protein'
  AND NOT EXISTS (
    SELECT 1 FROM products p
    WHERE p.brand_id = b.id AND p.name = 'Plant Protein Blend'
  );

WITH catalog (
  brand_name,
  category_slug,
  subcategory_slug,
  product_name,
  description,
  price_cents,
  cruelty_free,
  fragrance_free,
  vegan,
  skin_types,
  trending_score
) AS (
  VALUES
    ('Dewdrop Studio', 'skincare', 'moisturizer', 'Cloud Water Cream', 'A cooling gel cream for lightweight all-day hydration.', 2200, true, true, true, ARRAY['normal','oily','combination'], 9.1),
    ('Dewdrop Studio', 'skincare', 'serum', 'Milky Barrier Essence', 'A milky essence that supports a dry or stressed skin barrier.', 2600, true, true, true, ARRAY['dry','sensitive'], 8.9),
    ('Clear Theory', 'skincare', 'face-wash', 'Calm Reset Cleanser', 'A low-foam cleanser for acne-prone and reactive skin.', 1500, true, true, true, ARRAY['oily','sensitive'], 8.8),
    ('Clear Theory', 'skincare', 'serum', 'Azelaic Daily Serum', 'A gentle brightening serum for redness and post-acne marks.', 2100, true, true, true, ARRAY['oily','combination','sensitive'], 9.0),
    ('Kinly Lab', 'skincare', 'moisturizer', 'Ceramide Recovery Cream', 'A rich night cream with ceramides and soothing oat extract.', 2800, true, true, true, ARRAY['dry','sensitive'], 8.7),

    ('Root Ritual', 'haircare', 'conditioner', 'Silk Rinse Conditioner', 'A lightweight conditioner that smooths without flattening hair.', 2000, true, false, true, ARRAY[]::text[], 8.4),
    ('Curl Kind', 'haircare', 'shampoo', 'Curl Cleanse Wash', 'A gentle creamy cleanser made for curls and coils.', 2100, true, false, true, ARRAY[]::text[], 9.0),
    ('Curl Kind', 'haircare', 'conditioner', 'Deep Curl Mask', 'A rich weekly conditioning mask for dry textured hair.', 2600, true, false, true, ARRAY[]::text[], 9.2),
    ('Strand Lab', 'haircare', 'shampoo', 'Volume Reset Shampoo', 'A clarifying shampoo for fine hair and oily scalps.', 2300, true, false, true, ARRAY[]::text[], 8.6),
    ('Strand Lab', 'haircare', 'conditioner', 'Bond Repair Treatment', 'A strengthening treatment for colored and heat-damaged hair.', 3100, true, true, true, ARRAY[]::text[], 9.3),

    ('Muse Color', 'makeup', 'lipstick', 'Velvet Petal Lipstick', 'A soft-matte rose lipstick with comfortable long wear.', 1700, true, true, true, ARRAY[]::text[], 9.0),
    ('Muse Color', 'makeup', 'foundation', 'Second Skin Tint', 'A breathable light-coverage tint with a natural finish.', 2400, true, true, true, ARRAY[]::text[], 9.1),
    ('Bare Edit', 'makeup', 'foundation', 'Soft Focus Concealer', 'A flexible medium-coverage concealer for everyday wear.', 1800, true, true, true, ARRAY[]::text[], 8.8),
    ('Bare Edit', 'makeup', 'lipstick', 'Glass Lip Oil', 'A cushiony non-sticky lip oil with a sheer berry tint.', 1400, true, true, true, ARRAY[]::text[], 8.9),
    ('Everyday Beauty', 'makeup', 'foundation', 'Daily Skin Foundation', 'A buildable satin foundation designed for comfortable wear.', 2200, true, false, false, ARRAY[]::text[], 8.3),

    ('Everyday Beauty', 'body-care', NULL, 'Gentle Body Wash', 'A fragrance-free creamy body cleanser for everyday use.', 1300, true, true, true, ARRAY['sensitive'], 8.5),
    ('Soft Form', 'body-care', NULL, 'Oat Repair Body Cream', 'A rich oat and ceramide cream for dry, sensitive skin.', 1900, true, true, true, ARRAY['dry','sensitive'], 9.1),
    ('Soft Form', 'body-care', NULL, 'Daily Hand Balm', 'A fast-absorbing hand balm for frequent use.', 900, true, true, true, ARRAY['dry'], 8.2),
    ('Ritual Works', 'body-care', NULL, 'Neroli Shower Oil', 'A silky shower oil that cleanses while softening skin.', 2100, true, false, true, ARRAY['normal','dry'], 8.8),
    ('Ritual Works', 'body-care', NULL, 'Salt Polish Scrub', 'A smoothing body scrub with fine mineral salts and oils.', 2400, true, false, true, ARRAY['normal'], 8.6),

    ('Daily Balance', 'wellness', 'protein', 'Vanilla Protein Sachets', 'Single-serve plant protein sachets for travel and busy days.', 2800, true, true, true, ARRAY[]::text[], 8.4),
    ('Core Bloom', 'wellness', 'protein', 'Cocoa Recovery Protein', 'A chocolate plant protein blend designed for post-workout recovery.', 3400, true, true, true, ARRAY[]::text[], 9.0),
    ('Core Bloom', 'wellness', NULL, 'Daily Greens Blend', 'A mild greens powder with fiber and fruit extracts.', 3600, true, true, true, ARRAY[]::text[], 8.7),
    ('Good Habit', 'wellness', NULL, 'Magnesium Night Capsules', 'A simple magnesium supplement for evening routines.', 1800, true, true, true, ARRAY[]::text[], 8.8),
    ('Good Habit', 'wellness', NULL, 'Hydration Electrolyte Mix', 'Low-sugar citrus electrolyte sticks for daily hydration.', 1600, true, true, true, ARRAY[]::text[], 8.5),

    ('Form & Fold', 'fashion', 'dresses', 'Soft Column Dress', 'A versatile midi dress with a clean, relaxed silhouette.', 5200, false, false, false, ARRAY[]::text[], 8.8),
    ('Form & Fold', 'fashion', 'shoes', 'Minimal Leather Slides', 'Clean everyday slides with a cushioned footbed.', 4600, false, false, false, ARRAY[]::text[], 8.4),
    ('Sunday Studio', 'fashion', 'tops', 'Relaxed Linen Shirt', 'An oversized linen-blend shirt for easy layering.', 3800, false, false, false, ARRAY[]::text[], 9.0),
    ('Sunday Studio', 'fashion', 'dresses', 'Weekend Wrap Dress', 'A soft wrap dress designed for casual everyday wear.', 4900, false, false, false, ARRAY[]::text[], 8.7),
    ('Line & Loop', 'fashion', 'shoes', 'City Walk Sneakers', 'Minimal low-profile sneakers with a cushioned sole.', 5800, false, false, false, ARRAY[]::text[], 9.1),
    ('Line & Loop', 'fashion', 'tops', 'Structured Everyday Tee', 'A heavyweight cotton tee with a clean structured fit.', 2400, false, false, false, ARRAY[]::text[], 8.6)
)
INSERT INTO products (
  brand_id,
  category_id,
  subcategory_id,
  name,
  description,
  price_cents,
  cruelty_free,
  fragrance_free,
  vegan,
  skin_types,
  trending_score
)
SELECT
  b.id,
  c.id,
  s.id,
  catalog.product_name,
  catalog.description,
  catalog.price_cents,
  catalog.cruelty_free,
  catalog.fragrance_free,
  catalog.vegan,
  catalog.skin_types,
  catalog.trending_score
FROM catalog
JOIN brands b ON b.name = catalog.brand_name
JOIN categories c ON c.slug = catalog.category_slug
LEFT JOIN subcategories s ON s.slug = catalog.subcategory_slug
WHERE NOT EXISTS (
  SELECT 1
  FROM products existing
  WHERE existing.brand_id = b.id
    AND existing.name = catalog.product_name
);
