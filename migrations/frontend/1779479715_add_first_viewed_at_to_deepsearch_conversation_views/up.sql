ALTER TABLE deepsearch_conversation_views
    ADD COLUMN IF NOT EXISTS first_viewed_at TIMESTAMPTZ;

-- Backfill existing rows with the conversation's created_at as a lower-bound
-- proxy for first-view time. We don't have the real first-view timestamp for
-- rows that pre-date this column, but the view definitionally happened after
-- the conversation was created, so created_at is a safe and useful default.
UPDATE deepsearch_conversation_views v
SET first_viewed_at = c.created_at
FROM deepsearch_conversations c
WHERE c.read_token = v.read_token
  AND v.first_viewed_at IS NULL;

-- Belt-and-suspenders: if a view row exists without a matching conversation
-- (shouldn't happen given the data model), fall back to NOW() so the NOT NULL
-- constraint below holds.
UPDATE deepsearch_conversation_views
SET first_viewed_at = NOW()
WHERE first_viewed_at IS NULL;

ALTER TABLE deepsearch_conversation_views
    ALTER COLUMN first_viewed_at SET NOT NULL,
    ALTER COLUMN first_viewed_at SET DEFAULT NOW();

CREATE INDEX IF NOT EXISTS deepsearch_conversation_views_user_first_viewed
    ON deepsearch_conversation_views (tenant_id, user_id, first_viewed_at DESC);
