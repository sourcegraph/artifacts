TRUNCATE deepsearch_conversation_views;

ALTER TABLE deepsearch_conversation_views
    DROP COLUMN IF EXISTS conversation_id,
    DROP COLUMN IF EXISTS last_viewed_at,
    DROP COLUMN IF EXISTS view_count;

ALTER TABLE deepsearch_conversation_views
    ADD COLUMN IF NOT EXISTS read_token uuid NOT NULL;

ALTER TABLE deepsearch_conversation_views
    DROP CONSTRAINT IF EXISTS deepsearch_conversation_views_pkey;

ALTER TABLE deepsearch_conversation_views
    ADD CONSTRAINT deepsearch_conversation_views_pkey
    PRIMARY KEY (tenant_id, user_id, read_token);

DROP INDEX IF EXISTS deepsearch_conversation_views_user_recent;
