CREATE TABLE IF NOT EXISTS gitserver_continuity_manifests (
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    repo_id INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    generation BIGINT NOT NULL CHECK (generation > 0),
    manifest_digest TEXT NOT NULL,
    manifest_key TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT gitserver_continuity_manifests_pkey PRIMARY KEY (tenant_id, repo_id)
);

ALTER TABLE gitserver_continuity_manifests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON gitserver_continuity_manifests;
CREATE POLICY tenant_isolation_policy ON gitserver_continuity_manifests AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
