CREATE TABLE IF NOT EXISTS change_request_ci (
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    -- Results belong to this commit, not necessarily the PR's current head.
    head_oid TEXT NOT NULL,
    -- Preserve the code host's aggregate rather than recomputing it from checks.
    status TEXT NOT NULL DEFAULT 'UNKNOWN',
    checks JSONB NOT NULL DEFAULT '[]',
    -- A failed fetch can coexist with retained successful results for this head.
    sync_state TEXT NOT NULL DEFAULT 'PENDING',
    -- Last complete successful fetch; failures must not make old results look fresh.
    synced_at TIMESTAMPTZ,
    PRIMARY KEY (tenant_id, change_request_id)
);

ALTER TABLE change_request_ci ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_ci;
CREATE POLICY tenant_isolation_policy ON change_request_ci AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
