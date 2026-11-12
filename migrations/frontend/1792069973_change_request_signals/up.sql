CREATE TABLE IF NOT EXISTS review_semgrep_connections (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    base_url TEXT NOT NULL,
    deployment_id BIGINT NOT NULL,
    deployment_slug TEXT NOT NULL,
    deployment_name TEXT NOT NULL,
    token TEXT NOT NULL,
    encryption_key_id TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    -- A Semgrep token covers exactly one deployment, so a tenant has at most one connection.
    CONSTRAINT review_semgrep_connections_tenant_key UNIQUE (tenant_id)
);

ALTER TABLE review_semgrep_connections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON review_semgrep_connections;
CREATE POLICY tenant_isolation_policy ON review_semgrep_connections AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE TABLE IF NOT EXISTS change_request_signals (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    head_oid TEXT NOT NULL,
    kind TEXT NOT NULL,
    -- 'pending' signals wait for external data and are recomputed on the next synchronization.
    state TEXT NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT change_request_signals_key UNIQUE (tenant_id, change_request_id, head_oid, kind)
);

ALTER TABLE change_request_signals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_signals;
CREATE POLICY tenant_isolation_policy ON change_request_signals AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

-- The Semgrep refresher polls pending signals, least recently checked first.
CREATE INDEX IF NOT EXISTS change_request_signals_pending_idx
    ON change_request_signals (tenant_id, kind, updated_at)
    WHERE state = 'pending';
