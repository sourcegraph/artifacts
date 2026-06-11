CREATE TABLE IF NOT EXISTS changeset_hook_jobs (
    id BIGSERIAL PRIMARY KEY,

    -- Standard dbworker fields:
    state             text NOT NULL DEFAULT 'queued',
    failure_message   text,
    queued_at         timestamp with time zone NOT NULL DEFAULT NOW(),
    started_at        timestamp with time zone,
    finished_at       timestamp with time zone,
    process_after     timestamp with time zone,
    num_resets        integer NOT NULL DEFAULT 0,
    num_failures      integer NOT NULL DEFAULT 0,
    last_heartbeat_at timestamp with time zone,
    execution_logs    json[],
    worker_hostname   text NOT NULL DEFAULT '',
    cancel            boolean NOT NULL DEFAULT false,
    priority          integer NOT NULL DEFAULT 100,

    -- Hook job payload fields:
    changeset_id     bigint NOT NULL REFERENCES changesets(id) ON DELETE CASCADE DEFERRABLE,
    batch_change_id  bigint NOT NULL REFERENCES batch_changes(id) ON DELETE CASCADE DEFERRABLE,
    hook_type        text   NOT NULL,
    commit_oid       text,

    tenant_id        integer NOT NULL
                       DEFAULT (current_setting('app.current_tenant'::text))::integer
                       REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE
);

ALTER TABLE changeset_hook_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON changeset_hook_jobs;
CREATE POLICY tenant_isolation_policy ON changeset_hook_jobs AS PERMISSIVE FOR ALL TO PUBLIC USING (( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant)));

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_jobs_dedup_with_oid
    ON changeset_hook_jobs (changeset_id, tenant_id, hook_type, commit_oid)
    WHERE state IN ('queued', 'processing', 'errored')
      AND commit_oid IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_jobs_dedup_without_oid
    ON changeset_hook_jobs (changeset_id, tenant_id, hook_type)
    WHERE state IN ('queued', 'processing', 'errored')
      AND commit_oid IS NULL;

CREATE INDEX IF NOT EXISTS changeset_hook_jobs_dequeue_idx
    ON changeset_hook_jobs (state, process_after);

CREATE INDEX IF NOT EXISTS changeset_hook_jobs_dequeue_order_idx
    ON changeset_hook_jobs (priority DESC, COALESCE(process_after, queued_at) ASC, id ASC, tenant_id);

CREATE INDEX IF NOT EXISTS idx_changeset_hook_jobs_changeset_id
    ON changeset_hook_jobs (changeset_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_changeset_hook_jobs_batch_change_id
    ON changeset_hook_jobs (batch_change_id, tenant_id);
