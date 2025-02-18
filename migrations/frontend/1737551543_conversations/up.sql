CREATE TABLE IF NOT EXISTS agent_conversations (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data JSONB,
    agent_id INTEGER GENERATED ALWAYS AS ((data->>'agent_id')::integer) STORED REFERENCES agents(id) ON DELETE CASCADE,
    kind TEXT NOT NULL GENERATED ALWAYS AS (data->>'kind') STORED,
    external_api_url TEXT GENERATED ALWAYS AS (data->>'external_api_url') STORED,
    external_html_url TEXT GENERATED ALWAYS AS (data->>'external_html_url') STORED,
    rule_id TEXT GENERATED ALWAYS AS (data->>'rule_id') STORED,
    user_id INTEGER GENERATED ALWAYS AS ((data->>'user_id')::integer) STORED REFERENCES users(id) ON DELETE CASCADE,
    pull_request_id INTEGER GENERATED ALWAYS AS ((data->>'pull_request_id')::integer) STORED,
    diagnostic_id INTEGER GENERATED ALWAYS AS ((data->>'diagnostic_id')::integer) STORED REFERENCES agent_review_diagnostics(id) ON DELETE CASCADE,
    review_id INTEGER GENERATED ALWAYS AS ((data->>'review_id')::integer) STORED REFERENCES agent_reviews(id) ON DELETE CASCADE,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

ALTER TABLE agent_conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_conversations;
CREATE POLICY tenant_isolation_policy ON agent_conversations AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

-- Create indexes for List method
CREATE INDEX IF NOT EXISTS agent_conversations_kind_idx ON agent_conversations (kind);
CREATE INDEX IF NOT EXISTS agent_conversations_external_api_url_idx ON agent_conversations (external_api_url);
CREATE INDEX IF NOT EXISTS agent_conversations_external_html_url_idx ON agent_conversations (external_html_url);
CREATE INDEX IF NOT EXISTS agent_conversations_rule_id_idx ON agent_conversations (rule_id);
CREATE INDEX IF NOT EXISTS agent_conversations_user_id_idx ON agent_conversations (user_id);
CREATE INDEX IF NOT EXISTS agent_conversations_pull_request_id_idx ON agent_conversations (pull_request_id);
CREATE INDEX IF NOT EXISTS agent_conversations_agent_id_idx ON agent_conversations (agent_id);
CREATE INDEX IF NOT EXISTS agent_conversations_diagnostic_id_idx ON agent_conversations (diagnostic_id);
CREATE INDEX IF NOT EXISTS agent_conversations_review_id_idx ON agent_conversations (review_id);
CREATE INDEX IF NOT EXISTS agent_conversations_pull_request_id_idx ON agent_conversations (pull_request_id);

CREATE TABLE IF NOT EXISTS agent_conversation_messages (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    external_api_url TEXT GENERATED ALWAYS AS (data->>'external_api_url') STORED,
    external_html_url TEXT GENERATED ALWAYS AS (data->>'external_html_url') STORED,
    data JSONB,
    conversation_id INTEGER NOT NULL GENERATED ALWAYS AS ((data->>'conversation_id')::integer) STORED REFERENCES agent_conversations(id) ON DELETE CASCADE,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

CREATE INDEX IF NOT EXISTS agent_conversation_conversation_id_external_api_url_idx ON agent_conversation_messages (conversation_id, external_api_url);

ALTER TABLE agent_conversation_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_conversation_messages;
CREATE POLICY tenant_isolation_policy ON agent_conversation_messages AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
