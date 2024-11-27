CREATE POLICY isolation_policy_2 ON repo
    USING (
    (current_setting('app.current_tenant'::text) = 'zoekttenant') OR
    tenant_id = (NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant')::integer)
    );
DROP POLICY IF EXISTS repo_isolation_policy ON repo;
ALTER POLICY isolation_policy_2 ON repo
    RENAME TO repo_isolation_policy;

COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON gitserver_repos
    USING (
    (current_setting('app.current_tenant'::text) = 'zoekttenant') OR
    tenant_id = (NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant')::integer)
    );
DROP POLICY IF EXISTS gitserver_repos_isolation_policy ON gitserver_repos;
ALTER POLICY isolation_policy_2 ON gitserver_repos
    RENAME TO gitserver_repos_isolation_policy;

COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON zoekt_repos
    USING (
    (current_setting('app.current_tenant'::text) = 'zoekttenant') OR
    tenant_id = (NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant')::integer)
    );
DROP POLICY IF EXISTS zoekt_repos_isolation_policy ON zoekt_repos;
ALTER POLICY isolation_policy_2 ON zoekt_repos
    RENAME TO zoekt_repos_isolation_policy;
