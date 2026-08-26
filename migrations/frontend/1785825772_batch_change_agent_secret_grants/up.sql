-- Per-secret approval grants for agentic batch changes. A row means the user
-- pre-approved exposing the named execution secret to gated agent tool calls
-- (currently prepare_batch_spec), so the approval gate does not ask again:
-- either for one agent (agent_id set) or user-wide (agent_id NULL). The scope
-- is derived from agent_id NULL-ness; there is no separate scope column.
CREATE TABLE IF NOT EXISTS batch_change_agent_secret_grants (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    -- The granting (and granted) user: the agent owner who answered the
    -- approval. The gate only consults grants of the owner it asks.
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- NULL for user-wide grants. Hard agent deletion cascades; soft-deleted
    -- agents keep their rows, which is harmless (the agent no longer runs)
    -- and preserves history for a future grant-management UI.
    agent_id INTEGER REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    secret_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_secret_grants_secret_name_check
        CHECK (secret_name <> '')
);

-- Uniqueness is split into two partial indexes because agent_id is nullable;
-- both lead with tenant_id to keep the constraint tenant-isolated.
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_secret_grants_agent_scope_idx
    ON batch_change_agent_secret_grants (tenant_id, user_id, agent_id, secret_name)
    WHERE agent_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_secret_grants_user_scope_idx
    ON batch_change_agent_secret_grants (tenant_id, user_id, secret_name)
    WHERE agent_id IS NULL;

ALTER TABLE batch_change_agent_secret_grants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_secret_grants;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_secret_grants AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
