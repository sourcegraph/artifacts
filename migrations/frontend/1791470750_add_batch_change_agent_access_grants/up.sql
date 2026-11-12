-- Who may act on an agent. batch_change_agents.owner_user_id stays the
-- execution identity; this table holds the access relationships and their
-- provenance. A handover revokes the owner grant, creates one for the new
-- owner and leaves the previous owner a viewer grant.
CREATE TABLE IF NOT EXISTS batch_change_agent_access_grants (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    agent_id INTEGER NOT NULL REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    -- Deleting a user keeps the row as history.
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    relation TEXT NOT NULL,
    granted_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,

    CONSTRAINT batch_change_agent_access_grants_relation_check
        CHECK (relation IN ('owner', 'viewer'))
);

-- One active owner per agent.
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_access_grants_active_owner_idx
    ON batch_change_agent_access_grants (tenant_id, agent_id)
    WHERE relation = 'owner' AND revoked_at IS NULL;

-- One active grant per agent, user and relation; also serves the access check.
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_access_grants_active_user_idx
    ON batch_change_agent_access_grants (tenant_id, agent_id, user_id, relation)
    WHERE revoked_at IS NULL;

ALTER TABLE batch_change_agent_access_grants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_access_grants;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_access_grants AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

-- Every existing agent gets an owner grant for its current owner.
INSERT INTO batch_change_agent_access_grants (tenant_id, agent_id, user_id, relation, granted_by_user_id, created_at)
SELECT a.tenant_id, a.id, a.owner_user_id, 'owner', a.owner_user_id, a.created_at
FROM batch_change_agents a
WHERE NOT EXISTS (
    SELECT 1 FROM batch_change_agent_access_grants g
    WHERE g.agent_id = a.id AND g.relation = 'owner' AND g.revoked_at IS NULL
);
