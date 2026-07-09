CREATE TABLE IF NOT EXISTS executor_artifacts (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    uuid UUID NOT NULL,
    job_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    size_bytes BIGINT NULL,
    UNIQUE (tenant_id, uuid)
);

ALTER TABLE executor_artifacts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON executor_artifacts;
CREATE POLICY tenant_isolation_policy ON executor_artifacts AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
