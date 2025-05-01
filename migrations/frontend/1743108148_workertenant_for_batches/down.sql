CREATE POLICY isolation_policy_2 ON batch_spec_workspace_execution_last_dequeues USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON batch_spec_workspace_execution_last_dequeues;
ALTER POLICY isolation_policy_2 ON batch_spec_workspace_execution_last_dequeues RENAME TO tenant_isolation_policy;
