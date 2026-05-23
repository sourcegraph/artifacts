CREATE TABLE IF NOT EXISTS deepsearch_conversation_views (
    tenant_id       INTEGER     NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,
    user_id         INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id INTEGER     NOT NULL REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    last_viewed_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    view_count      INTEGER     NOT NULL DEFAULT 1,
    CONSTRAINT deepsearch_conversation_views_pkey
        PRIMARY KEY (tenant_id, user_id, conversation_id)
);

ALTER TABLE deepsearch_conversation_views ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_conversation_views;
CREATE POLICY tenant_isolation_policy ON deepsearch_conversation_views AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS deepsearch_conversation_views_user_recent
    ON deepsearch_conversation_views (tenant_id, user_id, last_viewed_at DESC);

CREATE INDEX IF NOT EXISTS deepsearch_conversation_views_per_conversation
    ON deepsearch_conversation_views (tenant_id, conversation_id);
