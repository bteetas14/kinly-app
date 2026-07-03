INSERT INTO users (
  email,
  username,
  password_hash,
  role,
  bio,
  reputation,
  trust_score,
  helpful_votes_received,
  created_at
) VALUES
  ('aarohi@demo.kinly', 'aarohi', crypt('DemoPass123!', gen_salt('bf')), 'user', 'Oily, acne-prone skin. I test products for at least four weeks.', 428, 86, 91, now() - interval '18 months'),
  ('mehak@demo.kinly', 'mehak', crypt('DemoPass123!', gen_salt('bf')), 'user', 'Skincare enthusiast focused on barrier repair and sunscreen.', 315, 79, 64, now() - interval '11 months'),
  ('simran@demo.kinly', 'simran', crypt('DemoPass123!', gen_salt('bf')), 'user', 'Curly hair, sensitive scalp, and always testing conditioners.', 267, 76, 48, now() - interval '9 months'),
  ('pooja@demo.kinly', 'pooja', crypt('DemoPass123!', gen_salt('bf')), 'user', 'Dry skin and minimalist makeup reviews.', 198, 72, 35, now() - interval '7 months'),
  ('everydaybeauty_team@demo.kinly', 'everydaybeauty_team', crypt('DemoPass123!', gen_salt('bf')), 'brand', 'Official Everyday Beauty team account.', 0, 100, 0, now() - interval '2 years')
ON CONFLICT (email) DO NOTHING;

INSERT INTO user_attributes (
  user_id,
  skin_type,
  sensitive_skin,
  favorite_categories,
  hair_type,
  skin_concerns,
  age_group
)
SELECT
  u.id,
  values.skin_type,
  values.sensitive_skin,
  values.favorite_categories,
  values.hair_type,
  values.skin_concerns,
  values.age_group
FROM users u
JOIN (
  VALUES
    ('aarohi', 'oily', true, ARRAY['Skincare','Makeup']::text[], 'straight', ARRAY['acne','redness']::text[], '18-24'),
    ('mehak', 'combination', true, ARRAY['Skincare','Body Care']::text[], 'wavy', ARRAY['dehydration','sensitivity']::text[], '25-34'),
    ('simran', 'normal', false, ARRAY['Haircare']::text[], 'curly', ARRAY[]::text[], '25-34'),
    ('pooja', 'dry', true, ARRAY['Skincare','Makeup']::text[], 'straight', ARRAY['dryness','pigmentation']::text[], '25-34')
) AS values(username, skin_type, sensitive_skin, favorite_categories, hair_type, skin_concerns, age_group)
  ON values.username = u.username
ON CONFLICT (user_id) DO UPDATE SET
  skin_type = EXCLUDED.skin_type,
  sensitive_skin = EXCLUDED.sensitive_skin,
  favorite_categories = EXCLUDED.favorite_categories,
  hair_type = EXCLUDED.hair_type,
  skin_concerns = EXCLUDED.skin_concerns,
  age_group = EXCLUDED.age_group;

UPDATE brands
SET owner_user_id = (
  SELECT id FROM users WHERE username = 'everydaybeauty_team'
)
WHERE name = 'Everyday Beauty';

WITH review_data (
  username,
  product_name,
  rating,
  title,
  body,
  pros,
  cons,
  would_buy_again,
  repurchased,
  verified_purchase,
  helpful_count,
  purchase_type,
  skin_type,
  hair_type,
  skin_concerns,
  age_group,
  follow_ups_completed,
  confidence,
  confidence_score,
  weighted_rating,
  created_offset
) AS (
  VALUES
    ('aarohi', 'Barrier Repair Serum', 5, 'Calmed my barrier in two weeks', 'This absorbed quickly and reduced the tight feeling around my cheeks. I used it twice daily without any clogged pores.', ARRAY['lightweight','soothing','layers well']::text[], ARRAY['small bottle']::text[], true, true, true, 42, 'bought_myself', 'oily', 'straight', ARRAY['acne','redness']::text[], '18-24', 2, 'high', 91, 4.55, interval '92 days'),
    ('mehak', 'Barrier Repair Serum', 4, 'Reliable under sunscreen', 'A dependable hydrating serum that sits well under sunscreen and makeup. It is not dramatic, but my skin feels more resilient.', ARRAY['hydrating','no pilling']::text[], ARRAY['slightly expensive']::text[], true, false, true, 28, 'bought_myself', 'combination', 'wavy', ARRAY['dehydration','sensitivity']::text[], '25-34', 1, 'high', 84, 3.36, interval '48 days'),
    ('pooja', 'Cloud Water Cream', 5, 'Perfect daytime moisturizer', 'It gives enough hydration for my dry patches without making the rest of my face greasy. The finish is smooth and comfortable.', ARRAY['light texture','comfortable finish']::text[], ARRAY['needs a richer night cream']::text[], true, true, false, 19, 'free_sample', 'dry', 'straight', ARRAY['dryness','pigmentation']::text[], '25-34', 1, 'medium', 68, 3.40, interval '36 days'),
    ('aarohi', 'Azelaic Daily Serum', 4, 'Slow but noticeable improvement', 'My post-acne marks look softer after six weeks and I had no stinging. It needs patience, but the formula feels balanced.', ARRAY['gentle','helps redness']::text[], ARRAY['slow results']::text[], true, false, true, 37, 'bought_myself', 'oily', 'straight', ARRAY['acne','redness']::text[], '18-24', 1, 'high', 88, 3.52, interval '54 days'),
    ('simran', 'Deep Curl Mask', 5, 'Defined curls without heaviness', 'My curls stayed soft for three wash days and the mask rinsed clean. A small amount was enough for my shoulder-length hair.', ARRAY['good slip','soft curls','concentrated']::text[], ARRAY['strong fragrance']::text[], true, true, true, 31, 'bought_myself', 'normal', 'curly', ARRAY[]::text[], '25-34', 2, 'high', 92, 4.60, interval '81 days'),
    ('simran', 'Bond Repair Treatment', 4, 'Helped after heat damage', 'The ends feel less rough after four uses. I would not use it every wash, but it works well as a weekly treatment.', ARRAY['strengthening','easy to rinse']::text[], ARRAY['can feel stiff if overused']::text[], true, false, false, 23, 'gifted', 'normal', 'curly', ARRAY[]::text[], '25-34', 1, 'medium', 71, 2.84, interval '44 days'),
    ('pooja', 'Velvet Petal Lipstick', 4, 'Comfortable soft matte', 'The color is wearable and the formula does not emphasize dry lips. It fades evenly after meals instead of becoming patchy.', ARRAY['comfortable','even fade']::text[], ARRAY['needs reapplication']::text[], true, false, true, 16, 'bought_myself', 'dry', 'straight', ARRAY['dryness']::text[], '25-34', 0, 'high', 79, 3.16, interval '21 days'),
    ('mehak', 'Oat Repair Body Cream', 5, 'Excellent for irritated winter skin', 'This stopped the itchy dry feeling on my arms within a few days. It is rich but does not leave a sticky film.', ARRAY['fragrance free','rich','non-sticky']::text[], ARRAY['tub packaging']::text[], true, true, true, 34, 'bought_myself', 'combination', 'wavy', ARRAY['sensitivity']::text[], '25-34', 1, 'high', 89, 4.45, interval '63 days'),
    ('pooja', 'Neroli Shower Oil', 3, 'Lovely texture, fragrance is strong', 'The oil texture leaves my skin soft, but the neroli scent lingers longer than I prefer. Better for fragrance lovers.', ARRAY['soft skin','luxurious texture']::text[], ARRAY['strong fragrance','pricey']::text[], false, false, false, 12, 'pr_package', 'dry', 'straight', ARRAY['dryness','sensitivity']::text[], '25-34', 0, 'low', 38, 1.14, interval '17 days'),
    ('aarohi', 'Daily Greens Blend', 3, 'Easy to mix but tastes grassy', 'It dissolves well in cold water and the sachets are convenient. The taste is quite green, so I prefer it in smoothies.', ARRAY['mixes easily','convenient']::text[], ARRAY['grassy taste']::text[], false, false, false, 9, 'free_sample', 'oily', 'straight', ARRAY[]::text[], '18-24', 0, 'medium', 57, 1.71, interval '12 days'),
    ('mehak', 'Second Skin Tint', 5, 'Looks like skin all day', 'The tint evens out redness without looking like foundation and wore well for eight hours. My sensitive skin stayed comfortable.', ARRAY['natural finish','comfortable','easy to blend']::text[], ARRAY['limited coverage']::text[], true, false, true, 26, 'bought_myself', 'combination', 'wavy', ARRAY['redness','sensitivity']::text[], '25-34', 0, 'high', 82, 4.10, interval '29 days'),
    ('pooja', 'Weekend Wrap Dress', 4, 'Easy shape and good fabric', 'The wrap stays secure and the fabric has enough weight to drape well. I would prefer pockets, but the fit is flattering.', ARRAY['flattering','comfortable fabric']::text[], ARRAY['no pockets']::text[], true, false, true, 14, 'bought_myself', 'dry', 'straight', ARRAY[]::text[], '25-34', 0, 'high', 80, 3.20, interval '24 days')
)
INSERT INTO reviews (
  product_id,
  user_id,
  rating,
  title,
  body,
  pros,
  cons,
  would_buy_again,
  repurchased,
  verified_purchase,
  helpful_count,
  purchase_type,
  skin_type,
  hair_type,
  skin_concerns,
  age_group,
  follow_ups_completed,
  confidence,
  confidence_score,
  weighted_rating,
  created_at,
  updated_at
)
SELECT
  p.id,
  u.id,
  data.rating,
  data.title,
  data.body,
  data.pros,
  data.cons,
  data.would_buy_again,
  data.repurchased,
  data.verified_purchase,
  data.helpful_count,
  data.purchase_type,
  data.skin_type,
  data.hair_type,
  data.skin_concerns,
  data.age_group,
  data.follow_ups_completed,
  data.confidence,
  data.confidence_score,
  data.weighted_rating,
  now() - data.created_offset,
  now() - data.created_offset
FROM review_data data
JOIN users u ON u.username = data.username
JOIN products p ON p.name = data.product_name
WHERE NOT EXISTS (
  SELECT 1
  FROM reviews existing
  WHERE existing.product_id = p.id
    AND existing.user_id = u.id
    AND existing.title = data.title
);

WITH followup_data (review_title, username, stage, body, still_using, would_buy_again, repurchased, created_offset) AS (
  VALUES
    ('Calmed my barrier in two weeks', 'aarohi', 'day_30', 'Still using this every morning. Redness is lower and it continues to layer well.', true, true, false, interval '62 days'),
    ('Calmed my barrier in two weeks', 'aarohi', 'day_90', 'Finished the bottle and repurchased. My barrier has stayed much more stable.', true, true, true, interval '2 days'),
    ('Defined curls without heaviness', 'simran', 'day_30', 'The softness is consistent and I now use it every third wash.', true, true, false, interval '51 days'),
    ('Defined curls without heaviness', 'simran', 'day_90', 'Repurchased the full size. It remains my most reliable deep conditioner.', true, true, true, interval '1 day'),
    ('Excellent for irritated winter skin', 'mehak', 'day_30', 'Still using it nightly and the dry patches have not returned.', true, true, true, interval '33 days')
)
INSERT INTO review_followups (
  review_id,
  user_id,
  stage,
  body,
  still_using,
  would_buy_again,
  repurchased,
  created_at
)
SELECT
  r.id,
  u.id,
  data.stage,
  data.body,
  data.still_using,
  data.would_buy_again,
  data.repurchased,
  now() - data.created_offset
FROM followup_data data
JOIN users u ON u.username = data.username
JOIN reviews r ON r.user_id = u.id AND r.title = data.review_title
ON CONFLICT (review_id, stage) DO NOTHING;

WITH post_data (username, community_slug, title, body, tags, upvotes, views, created_offset) AS (
  VALUES
    ('aarohi', 'acne', 'Azelaic acid or niacinamide for post-acne marks?', 'My active acne is mostly controlled, but I still have red and brown marks. Which ingredient gave you visible results without irritating your skin?', ARRAY['acne','ingredients','routine-help']::text[], 38, 412, interval '5 hours'),
    ('mehak', 'dry-skin', 'Barrier repair routine after over-exfoliating', 'I used too many exfoliating products last week and now even water stings. What is the simplest routine you would follow for the next seven days?', ARRAY['barrier-repair','sensitive-skin']::text[], 51, 638, interval '9 hours'),
    ('simran', 'haircare', 'Best lightweight conditioner for fine curly hair?', 'Most curl masks define my hair but remove all volume. Looking for something with slip that still rinses clean.', ARRAY['curly-hair','conditioner']::text[], 27, 291, interval '14 hours'),
    ('pooja', 'makeup', 'Skin tint that does not cling to dry patches', 'I want light coverage for redness, but most tints separate around my nose. What prep and products work for dry skin?', ARRAY['skin-tint','dry-skin']::text[], 23, 245, interval '1 day'),
    ('aarohi', 'general', 'Do you reapply sunscreen over makeup?', 'I understand the two-hour rule, but sprays and powders seem unreliable. What actually works without ruining makeup?', ARRAY['sunscreen','makeup']::text[], 44, 521, interval '2 days'),
    ('mehak', 'product-recommendations', 'Fragrance-free body lotion for humid weather', 'I need something for sensitive skin that absorbs quickly and does not feel sticky in summer.', ARRAY['body-care','fragrance-free']::text[], 19, 176, interval '3 days'),
    ('simran', 'ingredient-discussions', 'Do bond repair products help untreated hair?', 'My hair is not colored, but I use heat twice a week. Is bond repair useful or would a regular conditioning mask be better?', ARRAY['haircare','ingredients']::text[], 31, 354, interval '4 days'),
    ('pooja', 'routine-help', 'Minimal morning routine for very dry skin', 'Can I skip cleanser in the morning and just use moisturizer plus sunscreen? My face feels tight after every wash.', ARRAY['dry-skin','morning-routine']::text[], 36, 403, interval '5 days'),
    ('aarohi', 'general', 'What makes you trust a product review?', 'Do long-term updates matter more to you than verified purchase labels, detailed skin type, or review photos?', ARRAY['reviews','trust']::text[], 62, 744, interval '6 days'),
    ('mehak', 'kbeauty', 'Favorite calming toner with no fragrance?', 'Looking for a simple watery toner for redness. I would prefer no essential oils and no exfoliating acids.', ARRAY['kbeauty','sensitive-skin']::text[], 25, 218, interval '7 days')
)
INSERT INTO posts (
  community_id,
  author_id,
  title,
  body,
  tags,
  upvotes,
  views,
  created_at,
  updated_at
)
SELECT
  c.id,
  u.id,
  data.title,
  data.body,
  data.tags,
  data.upvotes,
  data.views,
  now() - data.created_offset,
  now() - data.created_offset
FROM post_data data
JOIN users u ON u.username = data.username
JOIN communities c ON c.slug = data.community_slug
WHERE NOT EXISTS (
  SELECT 1 FROM posts existing WHERE existing.title = data.title
);

WITH comment_data (post_title, username, body, created_offset) AS (
  VALUES
    ('Azelaic acid or niacinamide for post-acne marks?', 'mehak', 'Azelaic acid helped my redness more, but it took about six weeks. I introduced it every other night first.', interval '4 hours'),
    ('Azelaic acid or niacinamide for post-acne marks?', 'pooja', 'Niacinamide above 5% irritated me. A lower percentage plus sunscreen was easier to maintain.', interval '3 hours'),
    ('Barrier repair routine after over-exfoliating', 'aarohi', 'I would pause all actives, use a gentle cleanser only at night, then moisturizer and sunscreen.', interval '7 hours'),
    ('Best lightweight conditioner for fine curly hair?', 'mehak', 'Look for a regular conditioner with good slip instead of a heavy mask. Use the mask only on the ends.', interval '10 hours'),
    ('What makes you trust a product review?', 'pooja', 'Long-term updates and clear disclosure matter most to me. Photos help, but context is more useful.', interval '5 days'),
    ('is moxie leave in conditioner good?', 'simran', 'It worked better for me when I used half the recommended amount on soaking wet hair.', interval '2 hours'),
    ('is moxie leave in conditioner good?', 'aarohi', 'Tagging @smokeuser because the product seems best suited to fine curls rather than very dry coils.', interval '1 hour')
)
INSERT INTO comments (post_id, author_id, body, created_at, updated_at)
SELECT
  p.id,
  u.id,
  data.body,
  now() - data.created_offset,
  now() - data.created_offset
FROM comment_data data
JOIN posts p ON p.title = data.post_title
JOIN users u ON u.username = data.username
WHERE NOT EXISTS (
  SELECT 1
  FROM comments existing
  WHERE existing.post_id = p.id
    AND existing.author_id = u.id
    AND existing.body = data.body
);

INSERT INTO review_comments (review_id, author_id, body, created_at, updated_at)
SELECT
  r.id,
  u.id,
  'Thank you for the detailed feedback. We are testing a lighter texture for future batches.',
  now() - interval '3 hours',
  now() - interval '3 hours'
FROM reviews r
JOIN users u ON u.username = 'everydaybeauty_team'
WHERE r.title = 'too thick'
  AND NOT EXISTS (
    SELECT 1
    FROM review_comments existing
    WHERE existing.review_id = r.id
      AND existing.author_id = u.id
  );

INSERT INTO user_badges (user_id, badge_id, awarded_at)
SELECT u.id, b.id, now() - interval '1 day'
FROM users u, badges b
WHERE u.username = 'smokeuser'
  AND b.name = 'Early Supporter'
ON CONFLICT DO NOTHING;

WITH target AS (
  SELECT id FROM users WHERE username = 'smokeuser'
),
actors AS (
  SELECT username::text, id FROM users
),
smoke_review AS (
  SELECT id FROM reviews WHERE title = 'too thick' LIMIT 1
),
smoke_post AS (
  SELECT id FROM posts WHERE title = 'is moxie leave in conditioner good?' LIMIT 1
),
mention_post AS (
  SELECT id FROM posts WHERE title = 'What makes you trust a product review?' LIMIT 1
),
badge AS (
  SELECT id FROM badges WHERE name = 'Early Supporter'
)
INSERT INTO notifications (
  user_id,
  actor_id,
  type,
  title,
  body,
  resource_type,
  resource_id,
  read_at,
  created_at
)
SELECT
  target.id,
  actor.id,
  data.type,
  data.title,
  data.body,
  data.resource_type,
  CASE data.resource_key
    WHEN 'smoke_review' THEN (SELECT id FROM smoke_review)
    WHEN 'smoke_post' THEN (SELECT id FROM smoke_post)
    WHEN 'mention_post' THEN (SELECT id FROM mention_post)
    WHEN 'badge' THEN (SELECT id FROM badge)
  END,
  CASE WHEN data.is_read THEN now() - interval '30 minutes' ELSE NULL END,
  now() - data.created_offset
FROM target
JOIN (
  VALUES
    ('simran', 'reply', 'New reply to your question', 'Simran shared how she uses the Moxie leave-in on fine curls.', 'post', 'smoke_post', false, interval '2 hours'),
    ('aarohi', 'reply', 'Another community reply', 'Aarohi added a different perspective to your Haircare question.', 'post', 'smoke_post', false, interval '1 hour'),
    ('aarohi', 'mention', 'You were mentioned', 'Aarohi mentioned you in a discussion about trustworthy reviews.', 'post', 'mention_post', false, interval '45 minutes'),
    ('mehak', 'helpful_vote', 'Your review was helpful', 'Mehak found your sunscreen review helpful.', 'review', 'smoke_review', false, interval '4 hours'),
    ('pooja', 'helpful_vote', 'Another helpful vote', 'Pooja also found your sunscreen review useful.', 'review', 'smoke_review', true, interval '1 day'),
    ('everydaybeauty_team', 'brand_response', 'Everyday Beauty responded', 'The brand replied to your review about the sunscreen texture.', 'review', 'smoke_review', false, interval '3 hours'),
    (NULL, 'new_badge', 'You earned Early Supporter', 'This badge recognizes members who joined during Kinly''s early development.', 'badge', 'badge', true, interval '1 day'),
    ('simran', 'community_activity', 'New activity in Haircare', 'A new answer was added to a Haircare question you participated in.', 'post', 'smoke_post', false, interval '20 minutes'),
    ('mehak', 'community_activity', 'Trending in Routine Help', 'A barrier repair discussion is receiving useful new answers.', 'post', 'mention_post', true, interval '8 hours'),
    (NULL, 'review_reminder', 'Time for a 30-day update', 'Has the sunscreen texture or performance changed? Add a follow-up to your review.', 'review', 'smoke_review', false, interval '10 minutes'),
    (NULL, 'review_reminder', 'Long-term review reminder', 'Share whether you finished, repurchased, or stopped using this product.', 'review', 'smoke_review', true, interval '2 days')
) AS data(actor_username, type, title, body, resource_type, resource_key, is_read, created_offset)
  ON true
LEFT JOIN actors actor ON actor.username = data.actor_username
WHERE NOT EXISTS (
  SELECT 1
  FROM notifications existing
  WHERE existing.user_id = target.id
    AND existing.type = data.type
    AND existing.title = data.title
);

UPDATE reviews
SET helpful_count = GREATEST(helpful_count, 2)
WHERE title = 'too thick';

UPDATE users user_item
SET helpful_votes_received = stats.helpful_votes,
    reputation = stats.helpful_votes * 3
      + stats.review_count * 5
      + stats.post_count * 2
      + stats.comment_count,
    updated_at = now()
FROM (
  SELECT
    u.id,
    COALESCE((
      SELECT sum(r.helpful_count)::int
      FROM reviews r
      WHERE r.user_id = u.id AND r.deleted_at IS NULL
    ), 0) AS helpful_votes,
    (
      SELECT count(*)::int
      FROM reviews r
      WHERE r.user_id = u.id AND r.deleted_at IS NULL
    ) AS review_count,
    (
      SELECT count(*)::int
      FROM posts p
      WHERE p.author_id = u.id AND p.deleted_at IS NULL
    ) AS post_count,
    (
      SELECT count(*)::int
      FROM comments c
      WHERE c.author_id = u.id AND c.deleted_at IS NULL
    ) + (
      SELECT count(*)::int
      FROM review_comments rc
      WHERE rc.author_id = u.id AND rc.deleted_at IS NULL
    ) AS comment_count
  FROM users u
) stats
WHERE user_item.id = stats.id;
