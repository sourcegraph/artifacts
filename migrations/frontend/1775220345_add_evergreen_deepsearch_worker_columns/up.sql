ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS state TEXT NOT NULL DEFAULT 'completed';
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS failure_message TEXT;
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS queued_at TIMESTAMPTZ NOT NULL DEFAULT now();
-- Backfill queued_at to match created_at for pre-existing completed versions.
UPDATE evergreen_deepsearch_versions SET queued_at = created_at WHERE state = 'completed';
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS finished_at TIMESTAMPTZ;
-- Backfill started_at and finished_at for pre-existing completed versions so they
-- are consistent with the state column (completed rows should have timestamps set).
UPDATE evergreen_deepsearch_versions SET started_at = created_at, finished_at = created_at WHERE state = 'completed' AND started_at IS NULL;
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS process_after TIMESTAMPTZ;
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS num_resets INTEGER NOT NULL DEFAULT 0;
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS num_failures INTEGER NOT NULL DEFAULT 0;
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS last_heartbeat_at TIMESTAMPTZ;
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS execution_logs JSON[];
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS worker_hostname TEXT NOT NULL DEFAULT '';
ALTER TABLE evergreen_deepsearch_versions ADD COLUMN IF NOT EXISTS cancel BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS evergreen_deepsearch_versions_dequeue_idx
    ON evergreen_deepsearch_versions (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

DROP POLICY IF EXISTS tenant_isolation_policy ON evergreen_deepsearch_versions;
CREATE POLICY tenant_isolation_policy ON evergreen_deepsearch_versions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (((SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text))
        OR (tenant_id = (SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

ALTER TABLE evergreen_deepsearch ALTER COLUMN updated_at SET DEFAULT now();

CREATE OR REPLACE FUNCTION update_evergreen_deepsearch_updated_at()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_evergreen_deepsearch_updated_at ON evergreen_deepsearch;

CREATE TRIGGER update_evergreen_deepsearch_updated_at
    BEFORE UPDATE ON evergreen_deepsearch
    FOR EACH ROW
    EXECUTE FUNCTION update_evergreen_deepsearch_updated_at();
