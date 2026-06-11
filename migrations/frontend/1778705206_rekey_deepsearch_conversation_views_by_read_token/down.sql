TRUNCATE deepsearch_conversation_views;

ALTER TABLE deepsearch_conversation_views
    DROP COLUMN IF EXISTS read_token;

ALTER TABLE deepsearch_conversation_views
    ADD COLUMN IF NOT EXISTS conversation_id integer NOT NULL
    REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS last_viewed_at timestamp with time zone NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS view_count integer NOT NULL DEFAULT 1;

ALTER TABLE deepsearch_conversation_views
    DROP CONSTRAINT IF EXISTS deepsearch_conversation_views_pkey;

ALTER TABLE deepsearch_conversation_views
    ADD CONSTRAINT deepsearch_conversation_views_pkey
    PRIMARY KEY (tenant_id, user_id, conversation_id);

CREATE INDEX IF NOT EXISTS deepsearch_conversation_views_user_recent
    ON deepsearch_conversation_views (tenant_id, user_id, last_viewed_at DESC);

CREATE INDEX IF NOT EXISTS deepsearch_conversation_views_per_conversation
    ON deepsearch_conversation_views (tenant_id, conversation_id);
