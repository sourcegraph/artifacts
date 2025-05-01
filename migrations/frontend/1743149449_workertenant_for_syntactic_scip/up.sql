-- syntactic_scip_indexing_jobs_audit_logs is triggered by worker dequeues so
-- needs workertenant.

CREATE POLICY isolation_policy_2 ON syntactic_scip_indexing_jobs_audit_logs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON syntactic_scip_indexing_jobs_audit_logs;
ALTER POLICY isolation_policy_2 ON syntactic_scip_indexing_jobs_audit_logs RENAME TO tenant_isolation_policy;
