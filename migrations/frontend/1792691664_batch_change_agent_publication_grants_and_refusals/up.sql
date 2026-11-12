CREATE TABLE IF NOT EXISTS batch_change_agent_publication_grants (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    agent_id INTEGER REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    mode TEXT NOT NULL CHECK (mode IN ('none', 'branch', 'draft', 'ready')),
    repository_ids INTEGER[] NOT NULL,
    tool_approval_id BIGINT REFERENCES batch_change_agent_tool_approvals(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    -- Standing permission only carries drafts into future attended runs.
    CONSTRAINT batch_change_agent_publication_grants_standing_draft_check CHECK (agent_id IS NOT NULL OR mode = 'draft')
);
CREATE INDEX IF NOT EXISTS batch_change_agent_publication_grants_agent_scope_idx
    ON batch_change_agent_publication_grants (tenant_id, user_id, agent_id) WHERE agent_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_publication_grants_user_scope_idx
    ON batch_change_agent_publication_grants (tenant_id, user_id) WHERE agent_id IS NULL;
CREATE INDEX IF NOT EXISTS batch_change_agent_publication_grants_tool_approval_id_idx
    ON batch_change_agent_publication_grants (tool_approval_id) WHERE tool_approval_id IS NOT NULL;
ALTER TABLE batch_change_agent_publication_grants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_publication_grants;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_publication_grants AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE TABLE IF NOT EXISTS batch_change_agent_refusals (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    thread_entry_id BIGINT NOT NULL REFERENCES batch_change_agent_thread_entries(id) ON DELETE CASCADE,
    tool_name TEXT NOT NULL,
    code TEXT NOT NULL CHECK (code IN ('capability', 'credential', 'outside_grant', 'outside_scope')),
    mode TEXT NOT NULL DEFAULT '' CHECK (mode IN ('', 'none', 'branch', 'draft', 'ready')),
    host TEXT NOT NULL DEFAULT '',
    repository_ids INTEGER[] NOT NULL DEFAULT '{}',
    credential_status TEXT NOT NULL DEFAULT '' CHECK (credential_status IN ('', 'ok', 'missing', 'invalid', 'unverified', 'checks_unreadable')),
    credential_message TEXT NOT NULL DEFAULT '',
    credential_service_type TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS batch_change_agent_refusals_entry_tool_idx
    ON batch_change_agent_refusals (tenant_id, thread_entry_id, tool_name);
ALTER TABLE batch_change_agent_refusals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_refusals;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_refusals AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
COMMENT ON TABLE batch_change_agent_refusals IS 'Active server refusal facts, recorded at their thread entry timestamp and written with their tool result; cleared by an owner message or a later result of the same tool.';
