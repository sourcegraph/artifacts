CREATE TABLE IF NOT EXISTS slack_conversation_mappings (
    id SERIAL PRIMARY KEY,
    slack_channel TEXT NOT NULL,
    slack_thread_ts TEXT NOT NULL,
    deepsearch_conversation_id INTEGER NOT NULL,
    deepsearch_read_token TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    tenant_id INTEGER NOT NULL DEFAULT (current_setting('app.current_tenant')::integer),
    CONSTRAINT slack_conversation_mappings_channel_thread_key UNIQUE (tenant_id, slack_channel, slack_thread_ts)
);

ALTER TABLE slack_conversation_mappings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON slack_conversation_mappings;
CREATE POLICY tenant_isolation_policy ON slack_conversation_mappings AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
