CREATE TABLE IF NOT EXISTS repository_blocks (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    -- The normalized repository location, for example github.com/owner/name.
    repository TEXT NOT NULL CONSTRAINT repository_blocks_repository_nonempty CHECK (repository <> ''),
    reason TEXT NOT NULL DEFAULT '',
    -- Stable upstream identities (api.ExternalRepoSpec) of repositories that
    -- matched this rule, so that they stay blocked after upstream renames.
    external_repos JSONB NOT NULL DEFAULT '[]'::jsonb CONSTRAINT repository_blocks_external_repos_array CHECK (jsonb_typeof(external_repos) = 'array'),
    -- Known names and clone locations also match imports through Other connections.
    repository_locations TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT repository_blocks_tenant_repository_unique UNIQUE (tenant_id, repository)
);

CREATE INDEX IF NOT EXISTS repository_blocks_external_repos_idx ON repository_blocks USING GIN (external_repos jsonb_path_ops);
CREATE INDEX IF NOT EXISTS repository_blocks_locations_idx ON repository_blocks USING GIN (repository_locations);

ALTER TABLE repository_blocks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON repository_blocks;
CREATE POLICY tenant_isolation_policy ON repository_blocks AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
