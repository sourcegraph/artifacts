CREATE TABLE IF NOT EXISTS diff_tours (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,

    -- Identity: one row per comparison. base_oid/head_oid are resolved commit
    -- OIDs so the row is reproducible and cacheable.
    repo_id INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    base_oid TEXT NOT NULL,
    head_oid TEXT NOT NULL,

    -- tour holds the generated tour as an opaque JSON blob, NULL until the job
    -- completes.
    tour JSONB,

    -- Standard workerutil columns. This table doubles as its own dbworker
    -- queue: each row is both the job and its result.
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

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- One tour per comparison; re-requests reuse (and re-version) the same row
    -- via ON CONFLICT ON CONSTRAINT in the enqueue upsert.
    CONSTRAINT diff_tours_repo_base_head_key UNIQUE (tenant_id, repo_id, base_oid, head_oid)
);

ALTER TABLE diff_tours ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON diff_tours;
CREATE POLICY tenant_isolation_policy ON diff_tours
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant)
    );

-- Dequeue index for the dbworker.
CREATE INDEX IF NOT EXISTS diff_tours_dequeue_idx
    ON diff_tours USING btree (tenant_id, state, process_after, queued_at, id)
    WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));
