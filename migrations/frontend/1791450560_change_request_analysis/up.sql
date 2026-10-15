CREATE TABLE IF NOT EXISTS change_request_analysis_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    base_oid TEXT NOT NULL,
    head_oid TEXT NOT NULL,
    diff_base_oid TEXT,
    skipped BOOLEAN NOT NULL DEFAULT FALSE,
    state TEXT NOT NULL DEFAULT 'queued',
    queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    process_after TIMESTAMPTZ,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMPTZ,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    failure_message TEXT,
    cancel BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS change_request_analysis_jobs_dequeue_idx
    ON change_request_analysis_jobs (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');
CREATE INDEX IF NOT EXISTS change_request_analysis_jobs_snapshot_idx
    ON change_request_analysis_jobs (tenant_id, change_request_id, base_oid, head_oid, id DESC);
CREATE INDEX IF NOT EXISTS change_request_analysis_jobs_history_idx
    ON change_request_analysis_jobs (tenant_id, change_request_id, id DESC);

ALTER TABLE change_request_analysis_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_analysis_jobs;
CREATE POLICY tenant_isolation_policy ON change_request_analysis_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );

CREATE TABLE IF NOT EXISTS change_request_file_groupings (
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    diff_base_oid TEXT NOT NULL,
    head_oid TEXT NOT NULL,
    files JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (tenant_id, change_request_id, diff_base_oid, head_oid)
);

ALTER TABLE change_request_file_groupings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_file_groupings;
CREATE POLICY tenant_isolation_policy ON change_request_file_groupings AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE OR REPLACE FUNCTION enqueue_change_request_analysis() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF OLD.base_sha IS NOT DISTINCT FROM NEW.base_sha AND OLD.head_sha IS NOT DISTINCT FROM NEW.head_sha THEN
            RETURN NEW;
        END IF;
    END IF;
    INSERT INTO change_request_analysis_jobs (tenant_id, change_request_id, base_oid, head_oid)
    VALUES (NEW.tenant_id, NEW.id, NEW.base_sha, NEW.head_sha);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS change_request_analysis_enqueue ON change_requests;
CREATE TRIGGER change_request_analysis_enqueue
    AFTER INSERT OR UPDATE OF base_sha, head_sha ON change_requests
    FOR EACH ROW EXECUTE FUNCTION enqueue_change_request_analysis();
