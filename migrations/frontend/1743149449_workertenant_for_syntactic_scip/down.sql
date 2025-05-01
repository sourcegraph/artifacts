CREATE POLICY isolation_policy_2 ON syntactic_scip_indexing_jobs_audit_logs USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON syntactic_scip_indexing_jobs_audit_logs;
ALTER POLICY isolation_policy_2 ON syntactic_scip_indexing_jobs_audit_logs RENAME TO tenant_isolation_policy;
