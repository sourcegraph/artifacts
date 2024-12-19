CREATE TABLE IF NOT EXISTS query_runner_state (
    query text,
    last_executed timestamp with time zone,
    latest_result timestamp with time zone,
    exec_duration_ns bigint,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);
ALTER TABLE query_runner_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy_new ON query_runner_state USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
DROP POLICY IF EXISTS tenant_isolation_policy ON query_runner_state;
ALTER POLICY tenant_isolation_policy_new ON query_runner_state RENAME TO tenant_isolation_policy;
