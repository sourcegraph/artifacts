CREATE UNLOGGED TABLE IF NOT EXISTS agent_conversation_message_chunks (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    message_id BIGINT NOT NULL GENERATED ALWAYS AS ((data->>'message_id')::integer) STORED,
    data JSONB NOT NULL,
    FOREIGN KEY (message_id) REFERENCES agent_conversation_messages(id) ON DELETE CASCADE
);

ALTER TABLE agent_conversation_message_chunks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_conversation_message_chunks;
CREATE POLICY tenant_isolation_policy ON agent_conversation_message_chunks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
