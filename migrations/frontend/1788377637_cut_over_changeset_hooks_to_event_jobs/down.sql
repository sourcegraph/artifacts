-- Revoke every token owned by the new hook queue before removing its transient
-- jobs table.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = CURRENT_SCHEMA()
          AND table_name = 'changeset_hook_event_jobs'
    ) THEN
        EXECUTE $query$
            DELETE FROM executor_job_tokens AS tokens
            USING changeset_hook_event_jobs AS jobs
            WHERE tokens.tenant_id = jobs.tenant_id
              AND tokens.job_id = jobs.id
              AND tokens.queue = 'batches-hooks'
        $query$;
    END IF;
END;
$$;

DROP TABLE IF EXISTS changeset_hook_event_jobs;
DROP TABLE IF EXISTS changeset_hook_events;
DROP TABLE IF EXISTS executor_queues_seen;

-- The cutover deliberately discards hook history and in-flight work. A
-- rollback therefore restores the latest legacy shape, but leaves it empty.
CREATE TABLE IF NOT EXISTS changeset_hook_jobs (
    id BIGSERIAL PRIMARY KEY,

    state TEXT NOT NULL DEFAULT 'queued',
    failure_message TEXT,
    queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    process_after TIMESTAMPTZ,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMPTZ,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    cancel BOOLEAN NOT NULL DEFAULT FALSE,
    priority INTEGER NOT NULL DEFAULT 100,

    changeset_id BIGINT NOT NULL
        REFERENCES changesets(id) ON DELETE CASCADE DEFERRABLE,
    batch_change_id BIGINT NOT NULL
        REFERENCES batch_changes(id) ON DELETE CASCADE DEFERRABLE,
    hook_type TEXT NOT NULL,
    commit_oid TEXT,
    tenant_id INTEGER NOT NULL
        DEFAULT (current_setting('app.current_tenant'::text))::integer
        REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,
    changeset_spec_id BIGINT
);
COMMENT ON TABLE changeset_hook_jobs IS NULL;

ALTER TABLE changeset_hook_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON changeset_hook_jobs;
CREATE POLICY tenant_isolation_policy ON changeset_hook_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant'::text)
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text)::integer AS current_tenant)
    );

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_jobs_dedup_with_oid
    ON changeset_hook_jobs (
        changeset_id,
        tenant_id,
        hook_type,
        commit_oid,
        COALESCE(changeset_spec_id, 0)
    )
    WHERE state IN ('queued', 'processing', 'errored')
      AND commit_oid IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_jobs_dedup_without_oid
    ON changeset_hook_jobs (
        changeset_id,
        tenant_id,
        hook_type,
        COALESCE(changeset_spec_id, 0)
    )
    WHERE state IN ('queued', 'processing', 'errored')
      AND commit_oid IS NULL;

CREATE INDEX IF NOT EXISTS changeset_hook_jobs_dequeue_idx
    ON changeset_hook_jobs (state, process_after);

CREATE INDEX IF NOT EXISTS changeset_hook_jobs_dequeue_order_idx
    ON changeset_hook_jobs (
        priority DESC,
        COALESCE(process_after, queued_at) ASC,
        id ASC,
        tenant_id
    );

CREATE INDEX IF NOT EXISTS idx_changeset_hook_jobs_changeset_id
    ON changeset_hook_jobs (changeset_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_changeset_hook_jobs_batch_change_id
    ON changeset_hook_jobs (batch_change_id, tenant_id);

DROP VIEW IF EXISTS batch_spec_workspace_execution_jobs_with_rank;
ALTER TABLE batch_spec_workspace_execution_jobs
    ADD COLUMN IF NOT EXISTS changeset_hook_job_id BIGINT;
ALTER TABLE batch_spec_workspace_execution_jobs
    DROP CONSTRAINT IF EXISTS batch_spec_workspace_execution_jobs_no_legacy_hook_jobs;
COMMENT ON COLUMN batch_spec_workspace_execution_jobs.changeset_hook_job_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS batch_spec_workspace_execution_jobs_changeset_hook_job_id
    ON batch_spec_workspace_execution_jobs (tenant_id, changeset_hook_job_id)
    WHERE changeset_hook_job_id IS NOT NULL;

CREATE VIEW batch_spec_workspace_execution_jobs_with_rank WITH (security_invoker = true) AS
 SELECT j.id,
    j.batch_spec_workspace_id,
    j.state,
    j.failure_message,
    j.started_at,
    j.finished_at,
    j.process_after,
    j.num_resets,
    j.num_failures,
    j.execution_logs,
    j.worker_hostname,
    j.last_heartbeat_at,
    j.created_at,
    j.updated_at,
    j.cancel,
    j.queued_at,
    j.user_id,
    j.version,
    q.place_in_global_queue,
    q.place_in_user_queue,
    j.tenant_id,
    j.changeset_hook_job_id
   FROM batch_spec_workspace_execution_jobs AS j
   LEFT JOIN batch_spec_workspace_execution_queue AS q ON j.id = q.id;
