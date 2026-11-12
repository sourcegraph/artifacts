-- Code-host teams that change requests request reviews from. Teams are
-- identified by their code-host IDs, so renaming a team or its organization
-- keeps its review requests and membership. The organization login and slug are
-- only for display and are refreshed whenever a change request that requests the team is synchronized.
CREATE TABLE IF NOT EXISTS change_request_teams (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    external_service_type TEXT NOT NULL,
    code_host_url TEXT NOT NULL,
    external_id TEXT NOT NULL,
    organization_external_id TEXT NOT NULL,
    organization_login TEXT NOT NULL,
    slug TEXT NOT NULL,
    CONSTRAINT change_request_teams_key UNIQUE (tenant_id, external_service_type, code_host_url, external_id)
);

ALTER TABLE change_request_teams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_teams;
CREATE POLICY tenant_isolation_policy ON change_request_teams AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

-- The teams a change request currently requests a review from. Each
-- synchronization replaces the rows of the change request. Teams are never
-- deleted, so their references don't cascade.
CREATE TABLE IF NOT EXISTS change_request_requested_teams (
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    team_id BIGINT NOT NULL REFERENCES change_request_teams(id),
    CONSTRAINT change_request_requested_teams_pkey PRIMARY KEY (tenant_id, change_request_id, team_id)
);

CREATE INDEX IF NOT EXISTS change_request_requested_teams_team_idx
    ON change_request_requested_teams (tenant_id, team_id, change_request_id);

ALTER TABLE change_request_requested_teams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_requested_teams;
CREATE POLICY tenant_isolation_policy ON change_request_requested_teams AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

-- Team membership snapshots owned by the installation that read them.
-- Deleting an installation removes its snapshots; no user tokens are stored.
-- Replaces change_request_team_members, which identifies teams by slug.
CREATE TABLE IF NOT EXISTS change_request_team_memberships (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    github_app_installation_id INTEGER NOT NULL REFERENCES github_app_installs(id) ON DELETE CASCADE,
    team_id BIGINT NOT NULL REFERENCES change_request_teams(id),
    member_external_id TEXT NOT NULL,
    synced_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT change_request_team_memberships_key UNIQUE (tenant_id, github_app_installation_id, team_id, member_external_id)
);

CREATE INDEX IF NOT EXISTS change_request_team_memberships_member_idx
    ON change_request_team_memberships (tenant_id, member_external_id, team_id);

ALTER TABLE change_request_team_memberships ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_team_memberships;
CREATE POLICY tenant_isolation_policy ON change_request_team_memberships AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
