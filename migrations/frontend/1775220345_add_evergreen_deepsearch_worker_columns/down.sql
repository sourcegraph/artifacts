DROP TRIGGER IF EXISTS update_evergreen_deepsearch_updated_at ON evergreen_deepsearch;
DROP FUNCTION IF EXISTS update_evergreen_deepsearch_updated_at();
ALTER TABLE evergreen_deepsearch ALTER COLUMN updated_at DROP DEFAULT;

DROP INDEX IF EXISTS evergreen_deepsearch_versions_dequeue_idx;

ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS state;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS failure_message;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS queued_at;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS started_at;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS finished_at;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS process_after;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS num_resets;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS num_failures;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS last_heartbeat_at;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS execution_logs;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS worker_hostname;
ALTER TABLE evergreen_deepsearch_versions DROP COLUMN IF EXISTS cancel;

DROP POLICY IF EXISTS tenant_isolation_policy ON evergreen_deepsearch_versions;
CREATE POLICY tenant_isolation_policy ON evergreen_deepsearch_versions AS PERMISSIVE FOR ALL TO PUBLIC
    USING ((tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)))
    WITH CHECK ((tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
