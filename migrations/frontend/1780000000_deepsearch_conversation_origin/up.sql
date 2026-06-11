CREATE TABLE IF NOT EXISTS batch_change_agent_deepsearch_conversation_mappings (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    batch_change_agent_id INTEGER NOT NULL REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    deepsearch_conversation_id INTEGER NOT NULL REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_deepsearch_mappings_unique_deepsearch_id UNIQUE (tenant_id, deepsearch_conversation_id)
);

ALTER TABLE batch_change_agent_deepsearch_conversation_mappings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_deepsearch_conversation_mappings;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_deepsearch_conversation_mappings AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS batch_change_agent_deepsearch_mappings_agent_idx
    ON batch_change_agent_deepsearch_conversation_mappings (tenant_id, batch_change_agent_id, created_at DESC);
