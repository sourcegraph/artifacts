CREATE TABLE IF NOT EXISTS container_registry_manifests (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    repository TEXT NOT NULL,
    reference TEXT NOT NULL,
    digest TEXT NOT NULL,
    content_type TEXT NOT NULL,
    blob BYTEA NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT container_registry_manifests_repo_ref_key UNIQUE (tenant_id, repository, reference)
);

ALTER TABLE container_registry_manifests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON container_registry_manifests;
CREATE POLICY tenant_isolation_policy ON container_registry_manifests AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
