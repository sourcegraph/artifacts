CREATE TABLE IF NOT EXISTS codeintel_destination_backfill_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    upload_id INTEGER NOT NULL,
    state TEXT NOT NULL DEFAULT 'queued',
    queued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    process_after TIMESTAMP WITH TIME ZONE,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    failure_message TEXT,
    cancel BOOLEAN NOT NULL DEFAULT FALSE,
    round INTEGER NOT NULL DEFAULT 0,
    UNIQUE (tenant_id, upload_id)
);

COMMENT ON TABLE codeintel_destination_backfill_jobs IS 'Completed uploads the backfill planner selected to be written into the new code intelligence store. Jobs are kept once done, so every upload is planned once; the table is dropped once backfilling is over.';
COMMENT ON COLUMN codeintel_destination_backfill_jobs.upload_id IS 'The upload whose bundle to produce from the codeintel tables.';
COMMENT ON COLUMN codeintel_destination_backfill_jobs.state IS 'dbworker job state. Uploads that were already written are planned as completed.';
COMMENT ON COLUMN codeintel_destination_backfill_jobs.round IS 'The backfill round that planned the job. Producers drop what they cached of the tenant when a new round starts.';

CREATE INDEX IF NOT EXISTS codeintel_destination_backfill_jobs_dequeue
    ON codeintel_destination_backfill_jobs (state, process_after, id)
    WHERE state IN ('queued', 'errored');

ALTER TABLE codeintel_destination_backfill_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON codeintel_destination_backfill_jobs;
CREATE POLICY tenant_isolation_policy ON codeintel_destination_backfill_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (((SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = (SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE TABLE IF NOT EXISTS codeintel_destination_backfill_rounds (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    round INTEGER NOT NULL DEFAULT 0,
    state TEXT NOT NULL DEFAULT 'idle',
    reset_round INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id),
    CONSTRAINT codeintel_destination_backfill_rounds_state_check CHECK (state IN ('idle', 'starting', 'active'))
);

COMMENT ON TABLE codeintel_destination_backfill_rounds IS 'The backfill round of each tenant. Dropped with codeintel_destination_backfill_jobs once backfilling is over.';
COMMENT ON COLUMN codeintel_destination_backfill_rounds.round IS 'The current or last backfill round.';
COMMENT ON COLUMN codeintel_destination_backfill_rounds.state IS 'idle: no round runs, and the destination writer retires uploads. starting: a round waits for the write queue to empty. active: the round runs, and the destination writer retires no uploads.';
COMMENT ON COLUMN codeintel_destination_backfill_rounds.reset_round IS 'A round whose backfill work the destination writer could not ingest; the planner drops its work and starts the next round.';

ALTER TABLE codeintel_destination_backfill_rounds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON codeintel_destination_backfill_rounds;
CREATE POLICY tenant_isolation_policy ON codeintel_destination_backfill_rounds AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

ALTER TABLE codeintel_destination_write_jobs ADD COLUMN IF NOT EXISTS backfill_round INTEGER;

COMMENT ON COLUMN codeintel_destination_write_jobs.backfill_round IS 'The backfill round that produced the ingested bundle, or NULL for a bundle of the upload hook. A bundle of the backfill may omit documents it wrote in other bundles of its round.';
