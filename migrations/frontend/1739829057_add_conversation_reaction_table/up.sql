CREATE TABLE IF NOT EXISTS agent_conversation_message_reactions (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data JSONB,
    message_id INTEGER NOT NULL GENERATED ALWAYS AS ((data->>'message_id')::integer) STORED REFERENCES agent_conversation_messages(id) ON DELETE CASCADE,
    user_id INTEGER GENERATED ALWAYS AS ((data->>'user_id')::integer) STORED REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL GENERATED ALWAYS AS (data->>'content') STORED,
    external_service_type TEXT NOT NULL GENERATED ALWAYS AS (data->>'external_service_type') STORED,
    external_api_url TEXT GENERATED ALWAYS AS (data->>'external_api_url') STORED,
    external_html_url TEXT GENERATED ALWAYS AS (data->>'external_html_url') STORED,
    external_service_id TEXT GENERATED ALWAYS AS (data->>'external_service_id') STORED,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

-- Enable row level security
ALTER TABLE agent_conversation_message_reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_conversation_message_reactions;
CREATE POLICY tenant_isolation_policy ON agent_conversation_message_reactions AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS agent_conversation_message_reactions_message_id_idx ON agent_conversation_message_reactions (message_id);
CREATE INDEX IF NOT EXISTS agent_conversation_message_reactions_user_id_idx ON agent_conversation_message_reactions (user_id);
CREATE INDEX IF NOT EXISTS agent_conversation_message_reactions_external_service_id_idx ON agent_conversation_message_reactions (external_service_id);
