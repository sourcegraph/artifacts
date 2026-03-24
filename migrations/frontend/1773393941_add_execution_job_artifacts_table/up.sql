CREATE TABLE IF NOT EXISTS executor_artifacts (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    domain TEXT NOT NULL CHECK (domain IN ('agenticbatchchanges')),
    step TEXT NOT NULL,
    artifact_key TEXT NOT NULL,
    object_storage_key TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS executor_artifacts_lookup_idx ON executor_artifacts (domain, step, artifact_key);

ALTER TABLE executor_artifacts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON executor_artifacts;
CREATE POLICY tenant_isolation_policy ON executor_artifacts AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
