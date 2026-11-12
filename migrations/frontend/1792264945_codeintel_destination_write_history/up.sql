ALTER TABLE codeintel_destination_write_jobs ADD COLUMN IF NOT EXISTS produce_started_at TIMESTAMP WITH TIME ZONE;
COMMENT ON COLUMN codeintel_destination_write_jobs.produce_started_at IS 'Time the producer started writing the bundle of an ingestion. It finished when the ingestion was queued.';

CREATE TABLE IF NOT EXISTS codeintel_destination_write_history (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    upload_id INTEGER NOT NULL,
    op TEXT NOT NULL,
    outcome TEXT NOT NULL,
    backfill_round INTEGER,
    produce_started_at TIMESTAMP WITH TIME ZONE,
    queued_at TIMESTAMP WITH TIME ZONE NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE NOT NULL,
    num_failures INTEGER NOT NULL,
    num_resets INTEGER NOT NULL,
    batch_size INTEGER NOT NULL,
    failure_message TEXT
);

COMMENT ON TABLE codeintel_destination_write_history IS 'Destination writer jobs that ended, with their timings. The latest written job of a completed upload is kept while the upload exists; other jobs are kept for 30 days.';
COMMENT ON COLUMN codeintel_destination_write_history.op IS 'What the job did with the upload: ingest or delete.';
COMMENT ON COLUMN codeintel_destination_write_history.outcome IS 'How the job ended: written, deleted, dropped, or errored.';
COMMENT ON COLUMN codeintel_destination_write_history.backfill_round IS 'The backfill round that produced the bundle of an ingestion, or NULL for the upload hook.';
COMMENT ON COLUMN codeintel_destination_write_history.produce_started_at IS 'Time the producer started writing the bundle of an ingestion. It finished at queued_at.';
COMMENT ON COLUMN codeintel_destination_write_history.queued_at IS 'Time the job was last queued.';
COMMENT ON COLUMN codeintel_destination_write_history.started_at IS 'Time the last attempt of the job began, shared by the jobs of its batch.';
COMMENT ON COLUMN codeintel_destination_write_history.finished_at IS 'Time the job ended.';
COMMENT ON COLUMN codeintel_destination_write_history.batch_size IS 'Number of jobs that ended together with this one, such as the uploads of one wave.';
COMMENT ON COLUMN codeintel_destination_write_history.failure_message IS 'Most recent failure of the job.';

CREATE INDEX IF NOT EXISTS codeintel_destination_write_history_upload_id
    ON codeintel_destination_write_history (tenant_id, upload_id, id);
CREATE INDEX IF NOT EXISTS codeintel_destination_write_history_finished_at
    ON codeintel_destination_write_history (tenant_id, finished_at);

ALTER TABLE codeintel_destination_write_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON codeintel_destination_write_history;
CREATE POLICY tenant_isolation_policy ON codeintel_destination_write_history AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
