INSERT INTO categories (name, slug) VALUES
  ('Skincare', 'skincare'),
  ('Haircare', 'haircare'),
  ('Makeup', 'makeup'),
  ('Body Care', 'body-care'),
  ('Wellness', 'wellness'),
  ('Fashion', 'fashion')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO subcategories (category_id, name, slug)
SELECT c.id, x.name, x.slug
FROM categories c
JOIN (VALUES
  ('skincare', 'Face Wash', 'face-wash'),
  ('skincare', 'Serum', 'serum'),
  ('skincare', 'Moisturizer', 'moisturizer'),
  ('skincare', 'Sunscreen', 'sunscreen'),
  ('haircare', 'Shampoo', 'shampoo'),
  ('haircare', 'Conditioner', 'conditioner'),
  ('makeup', 'Lipstick', 'lipstick'),
  ('makeup', 'Foundation', 'foundation'),
  ('wellness', 'Protein', 'protein'),
  ('fashion', 'Dresses', 'dresses'),
  ('fashion', 'Tops', 'tops'),
  ('fashion', 'Shoes', 'shoes')
) AS x(category_slug, name, slug) ON x.category_slug = c.slug
ON CONFLICT (slug) DO NOTHING;

INSERT INTO badges (name, description) VALUES
  ('Top Reviewer', 'Writes trusted, high-quality reviews.'),
  ('Community Favorite', 'Receives consistent community appreciation.'),
  ('Ingredient Geek', 'Contributes detailed ingredient insight.'),
  ('Acne Expert', 'Shares helpful acne-focused advice.'),
  ('Sunscreen Expert', 'Shares helpful sunscreen advice.'),
  ('Early Supporter', 'Joined during the early Kinly launch.'),
  ('100 Reviews Club', 'Published 100 reviews.'),
  ('1000 Helpful Votes Club', 'Received 1000 helpful votes.')
ON CONFLICT (name) DO NOTHING;

INSERT INTO communities (name, slug, description) VALUES
  ('General', 'general', 'General beauty, wellness, and fashion conversation.'),
  ('Acne', 'acne', 'Acne routines, product questions, and support.'),
  ('Dry Skin', 'dry-skin', 'Dry skin routines and recommendations.'),
  ('Oily Skin', 'oily-skin', 'Oily skin routines and recommendations.'),
  ('KBeauty', 'kbeauty', 'Korean beauty products and routines.'),
  ('Haircare', 'haircare', 'Haircare products, routines, and troubleshooting.'),
  ('Makeup', 'makeup', 'Makeup products, looks, and techniques.'),
  ('Routine Help', 'routine-help', 'Get help building or fixing a routine.'),
  ('Product Recommendations', 'product-recommendations', 'Ask for and share recommendations.'),
  ('Ingredient Discussions', 'ingredient-discussions', 'Ingredient education and analysis.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO brands (name, description, website_url) VALUES
  ('Kinly Lab', 'Sample skincare brand for local development.', 'https://example.com/kinly-lab'),
  ('Everyday Beauty', 'Sample beauty and body care brand.', 'https://example.com/everyday-beauty')
ON CONFLICT (name) DO NOTHING;

INSERT INTO products (brand_id, category_id, subcategory_id, name, description, price_cents, cruelty_free, fragrance_free, vegan, skin_types, trending_score)
SELECT b.id, c.id, s.id, 'Barrier Repair Serum', 'A lightweight serum for barrier support and daily hydration.', 2400, true, true, true, ARRAY['dry', 'sensitive'], 9.4
FROM brands b, categories c, subcategories s
WHERE b.name = 'Kinly Lab' AND c.slug = 'skincare' AND s.slug = 'serum'
ON CONFLICT DO NOTHING;

INSERT INTO products (brand_id, category_id, subcategory_id, name, description, price_cents, cruelty_free, fragrance_free, vegan, skin_types, trending_score)
SELECT b.id, c.id, s.id, 'Everyday Mineral Sunscreen SPF 50', 'A mineral sunscreen with a soft natural finish.', 1800, true, true, false, ARRAY['normal', 'oily', 'sensitive'], 8.7
FROM brands b, categories c, subcategories s
WHERE b.name = 'Everyday Beauty' AND c.slug = 'skincare' AND s.slug = 'sunscreen'
ON CONFLICT DO NOTHING;
