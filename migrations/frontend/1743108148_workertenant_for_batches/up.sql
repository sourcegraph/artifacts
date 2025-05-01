-- batch_spec_workspace_execution_last_dequeues is triggered by worker
-- dequeues so needs workertenant.

CREATE POLICY isolation_policy_2 ON batch_spec_workspace_execution_last_dequeues USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON batch_spec_workspace_execution_last_dequeues;
ALTER POLICY isolation_policy_2 ON batch_spec_workspace_execution_last_dequeues RENAME TO tenant_isolation_policy;
