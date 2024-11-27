CREATE POLICY isolation_policy_2 ON repo USING (tenant_id = (current_setting('app.current_tenant'::text)::integer));
DROP POLICY repo_isolation_policy ON repo;
ALTER POLICY isolation_policy_2 ON repo RENAME TO repo_isolation_policy;

COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON zoekt_repos USING (tenant_id = (current_setting('app.current_tenant'::text)::integer));
DROP POLICY zoekt_repos_isolation_policy ON zoekt_repos;
ALTER POLICY isolation_policy_2 ON zoekt_repos RENAME TO zoekt_repos_isolation_policy;

COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON gitserver_repos USING (tenant_id = (current_setting('app.current_tenant'::text)::integer));
DROP POLICY gitserver_repos_isolation_policy ON gitserver_repos;
ALTER POLICY isolation_policy_2 ON gitserver_repos RENAME TO gitserver_repos_isolation_policy;
