-- GitHub membership snapshots owned by the installation that can read them.
-- Deleting an installation removes its snapshots; no user tokens are stored.
CREATE TABLE IF NOT EXISTS change_request_team_members (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    github_app_installation_id INTEGER NOT NULL REFERENCES github_app_installs(id) ON DELETE CASCADE,
    team_slug TEXT NOT NULL,
    member_id TEXT NOT NULL,
    synced_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT change_request_team_members_key UNIQUE (tenant_id, github_app_installation_id, team_slug, member_id)
);

ALTER TABLE change_request_team_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_team_members;
CREATE POLICY tenant_isolation_policy ON change_request_team_members AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
