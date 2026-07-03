DELETE FROM notifications
WHERE type IN ('community_activity', 'review_reminder');

ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications
  ADD CONSTRAINT notifications_type_check CHECK (
    type IN (
      'reply',
      'mention',
      'helpful_vote',
      'brand_response',
      'new_badge',
      'follow'
    )
  );
