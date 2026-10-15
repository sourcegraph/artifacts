CREATE TABLE IF NOT EXISTS codeintel_destination_write_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    upload_id INTEGER NOT NULL,
    state TEXT NOT NULL DEFAULT 'queued',
    num_failures INTEGER NOT NULL DEFAULT 0,
    num_resets INTEGER NOT NULL DEFAULT 0,
    failure_message TEXT,
    queued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    process_after TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    op TEXT NOT NULL DEFAULT 'ingest',
    UNIQUE (tenant_id, upload_id)
);

COMMENT ON TABLE codeintel_destination_write_jobs IS 'Uploads the destination writer must write into or delete from the new code intelligence store. A job is deleted once it is done.';
COMMENT ON COLUMN codeintel_destination_write_jobs.id IS 'Unique queue job identifier.';
COMMENT ON COLUMN codeintel_destination_write_jobs.tenant_id IS 'Tenant that owns the upload and queue job.';
COMMENT ON COLUMN codeintel_destination_write_jobs.upload_id IS 'The upload whose bundle to write.';
COMMENT ON COLUMN codeintel_destination_write_jobs.state IS 'Job state: queued, processing, or errored.';
COMMENT ON COLUMN codeintel_destination_write_jobs.num_failures IS 'Number of failed processing attempts.';
COMMENT ON COLUMN codeintel_destination_write_jobs.num_resets IS 'Number of processing attempts that were interrupted.';
COMMENT ON COLUMN codeintel_destination_write_jobs.failure_message IS 'Most recent processing failure.';
COMMENT ON COLUMN codeintel_destination_write_jobs.queued_at IS 'Time the upload was last enqueued.';
COMMENT ON COLUMN codeintel_destination_write_jobs.started_at IS 'Time the most recent processing attempt began.';
COMMENT ON COLUMN codeintel_destination_write_jobs.finished_at IS 'Time the job errored.';
COMMENT ON COLUMN codeintel_destination_write_jobs.op IS 'What the destination writer does with the upload: ingest writes its bundle, delete detaches it. A job always holds the latest intent for its upload.';
COMMENT ON COLUMN codeintel_destination_write_jobs.process_after IS 'Earliest time the job may be dequeued: when it was queued, or after the backoff of a failed attempt.';

CREATE INDEX IF NOT EXISTS codeintel_destination_write_jobs_dequeue
    ON codeintel_destination_write_jobs (tenant_id, process_after, id)
    WHERE state = 'queued';

ALTER TABLE codeintel_destination_write_jobs ENABLE ROW LEVEL SECURITY;
-- Retiring an upload enqueues its deletion, so the policy must admit the
-- worker tenant that the upload workers update scip_uploads as.
DROP POLICY IF EXISTS tenant_isolation_policy ON codeintel_destination_write_jobs;
CREATE POLICY tenant_isolation_policy ON codeintel_destination_write_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (((SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = (SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

-- Enqueuing a deletion replaces whatever the upload's job holds, including an
-- ingestion being processed: the writer's fenced completion of that attempt
-- then leaves the deletion queued. Deletions are due at once.
CREATE OR REPLACE FUNCTION func_codeintel_destination_retired_upload() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO codeintel_destination_write_jobs (tenant_id, upload_id, op, queued_at, process_after)
        VALUES (NEW.tenant_id, NEW.id, 'delete', NOW(), '-infinity')
        ON CONFLICT ON CONSTRAINT codeintel_destination_write_jobs_tenant_id_upload_id_key DO UPDATE SET
            op = 'delete', state = 'queued', num_failures = 0, num_resets = 0, failure_message = NULL,
            queued_at = EXCLUDED.queued_at, started_at = NULL, finished_at = NULL, process_after = EXCLUDED.process_after;
        RETURN NULL;
    END;
$$;

CREATE OR REPLACE FUNCTION func_codeintel_destination_deleted_uploads() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO codeintel_destination_write_jobs (tenant_id, upload_id, op, queued_at, process_after)
        SELECT o.tenant_id, o.id, 'delete', NOW(), '-infinity' FROM old o ORDER BY o.id
        ON CONFLICT ON CONSTRAINT codeintel_destination_write_jobs_tenant_id_upload_id_key DO UPDATE SET
            op = 'delete', state = 'queued', num_failures = 0, num_resets = 0, failure_message = NULL,
            queued_at = EXCLUDED.queued_at, started_at = NULL, finished_at = NULL, process_after = EXCLUDED.process_after;
        RETURN NULL;
    END;
$$;

-- An upload is retired once it is deleting, deleted, failed, superseded or
-- canceled; the destination must not serve it.
DROP TRIGGER IF EXISTS trigger_codeintel_destination_retired_upload ON scip_uploads;
CREATE TRIGGER trigger_codeintel_destination_retired_upload AFTER UPDATE OF state ON scip_uploads FOR EACH ROW
    WHEN (NEW.state IN ('deleting', 'deleted', 'failed', 'superseded', 'canceled')
        AND OLD.state NOT IN ('deleting', 'deleted', 'failed', 'superseded', 'canceled'))
    EXECUTE FUNCTION func_codeintel_destination_retired_upload();

DROP TRIGGER IF EXISTS trigger_codeintel_destination_deleted_uploads ON scip_uploads;
CREATE TRIGGER trigger_codeintel_destination_deleted_uploads AFTER DELETE ON scip_uploads
    REFERENCING OLD TABLE AS old FOR EACH STATEMENT
    EXECUTE FUNCTION func_codeintel_destination_deleted_uploads();
