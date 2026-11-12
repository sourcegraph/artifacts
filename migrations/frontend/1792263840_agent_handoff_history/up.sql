CREATE TABLE IF NOT EXISTS agent_handoff_connections (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    target TEXT NOT NULL,
    credential_id BIGINT REFERENCES user_credentials(id) ON DELETE SET NULL,
    UNIQUE (tenant_id, user_id, provider, target)
);

COMMENT ON TABLE agent_handoff_connections IS 'Stable personal coding-agent connectors; disconnecting removes the credential, not the connector or its history.';

CREATE TABLE IF NOT EXISTS agent_handoffs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    connection_id BIGINT NOT NULL REFERENCES agent_handoff_connections(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    instructions TEXT NOT NULL,
    source JSONB,
    status TEXT NOT NULL DEFAULT 'submitting',
    vendor_url TEXT NOT NULL DEFAULT '',
    error TEXT NOT NULL DEFAULT '',
    idempotency_key UUID,
    CONSTRAINT agent_handoffs_idempotency_key UNIQUE (tenant_id, connection_id, idempotency_key)
);

COMMENT ON COLUMN agent_handoffs.source IS 'Optional {kind, id, title} reference. Deliberately not a foreign key: source deletion must not remove handoff history.';
COMMENT ON COLUMN agent_handoffs.status IS 'Submission outcome, not the state of the coding task: submitting, submitted, failed, or unconfirmed.';

CREATE INDEX IF NOT EXISTS agent_handoffs_connection_id_id ON agent_handoffs (connection_id, id DESC);
-- Supports future source-scoped history across connectors without coupling
-- handoff retention to the triggering resource's lifetime.
CREATE INDEX IF NOT EXISTS agent_handoffs_source_id ON agent_handoffs
    (tenant_id, (source->>'kind'), (source->>'id'), id DESC);
CREATE INDEX IF NOT EXISTS agent_handoff_connections_credential_id ON agent_handoff_connections (credential_id);
CREATE INDEX IF NOT EXISTS agent_handoffs_stale_submissions
    ON agent_handoffs (tenant_id, updated_at) WHERE status = 'submitting';

ALTER TABLE agent_handoff_connections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_handoff_connections;
CREATE POLICY tenant_isolation_policy ON agent_handoff_connections AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

ALTER TABLE agent_handoffs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_handoffs;
CREATE POLICY tenant_isolation_policy ON agent_handoffs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
