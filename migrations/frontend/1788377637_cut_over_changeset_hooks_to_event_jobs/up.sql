-- Durable hook-domain events. Live dbworker/executor state belongs to the
-- separate changeset_hook_event_jobs table below.
CREATE TABLE IF NOT EXISTS changeset_hook_events (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL
        DEFAULT (current_setting('app.current_tenant'::text))::integer
        REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    changeset_id BIGINT NOT NULL
        REFERENCES changesets(id) ON DELETE CASCADE DEFERRABLE,
    batch_change_id BIGINT NOT NULL
        REFERENCES batch_changes(id) ON DELETE CASCADE DEFERRABLE,
    hook_type TEXT NOT NULL,
    commit_oid TEXT,
    hooks_hash TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    version INTEGER NOT NULL,

    state TEXT NOT NULL DEFAULT 'pending',
    skip_reason TEXT,
    attempt_counted BOOLEAN NOT NULL DEFAULT FALSE,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    failure_message TEXT,

    last_observed_at TIMESTAMPTZ,
    observation_count INTEGER
);

ALTER TABLE changeset_hook_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON changeset_hook_events;
CREATE POLICY tenant_isolation_policy ON changeset_hook_events AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_events_dedup_with_oid
    ON changeset_hook_events (tenant_id, changeset_id, hook_type, commit_oid, hooks_hash)
    WHERE commit_oid IS NOT NULL
      AND (state = 'pending' OR attempt_counted OR skip_reason = 'unsupported_changeset');

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_events_pending_without_oid
    ON changeset_hook_events (tenant_id, changeset_id, hook_type, hooks_hash)
    WHERE commit_oid IS NULL
      AND (state = 'pending' OR skip_reason = 'unsupported_changeset');

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_events_exhaustion
    ON changeset_hook_events (tenant_id, changeset_id, hook_type, hooks_hash)
    WHERE skip_reason = 'max_attempts_exhausted';

CREATE INDEX IF NOT EXISTS changeset_hook_events_changeset_id
    ON changeset_hook_events (tenant_id, changeset_id, id DESC);

CREATE INDEX IF NOT EXISTS changeset_hook_events_batch_change_hook_type
    ON changeset_hook_events (batch_change_id, tenant_id, hook_type);

-- Transient dbworker and executor mechanics for a durable hook event.
CREATE TABLE IF NOT EXISTS changeset_hook_event_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL
        DEFAULT (current_setting('app.current_tenant'::text))::integer
        REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,
    changeset_hook_event_id BIGINT NOT NULL
        REFERENCES changeset_hook_events(id) ON DELETE CASCADE DEFERRABLE,

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

    CONSTRAINT changeset_hook_event_jobs_event_key UNIQUE (tenant_id, changeset_hook_event_id)
);

ALTER TABLE changeset_hook_event_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON changeset_hook_event_jobs;
CREATE POLICY tenant_isolation_policy ON changeset_hook_event_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant'::text)
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text)::integer AS current_tenant)
    );

CREATE INDEX IF NOT EXISTS changeset_hook_event_jobs_dequeue
    ON changeset_hook_event_jobs (state, process_after);

CREATE INDEX IF NOT EXISTS changeset_hook_event_jobs_reconcile
    ON changeset_hook_event_jobs (state, finished_at);

-- Record that an executor has declared a queue at least once. Unlike
-- executor_heartbeats, these rows are intentionally not removed when an
-- executor pool is inactive or scaled to zero.
CREATE TABLE IF NOT EXISTS executor_queues_seen (
    tenant_id INTEGER NOT NULL
        DEFAULT (current_setting('app.current_tenant'::text))::integer
        REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,
    queue_name TEXT NOT NULL,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (tenant_id, queue_name)
);

ALTER TABLE executor_queues_seen ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON executor_queues_seen;
CREATE POLICY tenant_isolation_policy ON executor_queues_seen AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

INSERT INTO executor_queues_seen (tenant_id, queue_name, first_seen_at, last_seen_at)
SELECT tenant_id, queue_name, MIN(first_seen_at), MAX(last_seen_at)
FROM (
    SELECT tenant_id, queue_name, first_seen_at, last_seen_at
    FROM executor_heartbeats
    WHERE queue_name IS NOT NULL

    UNION ALL

    SELECT heartbeats.tenant_id, names.queue_name, heartbeats.first_seen_at, heartbeats.last_seen_at
    FROM executor_heartbeats AS heartbeats
    CROSS JOIN LATERAL UNNEST(heartbeats.queue_names) AS names(queue_name)
) AS declared_queues
WHERE queue_name <> ''
GROUP BY tenant_id, queue_name
ON CONFLICT (tenant_id, queue_name) DO UPDATE
SET first_seen_at = LEAST(executor_queues_seen.first_seen_at, EXCLUDED.first_seen_at),
    last_seen_at = GREATEST(executor_queues_seen.last_seen_at, EXCLUDED.last_seen_at);

-- Revoke credentials before deleting old hook-backed workspace executions.
-- The conditional dynamic SQL limits the cleanup to schemas where the legacy
-- discriminator is available.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = CURRENT_SCHEMA()
          AND table_name = 'batch_spec_workspace_execution_jobs'
          AND column_name = 'changeset_hook_job_id'
    ) THEN
        -- Legacy hook inbox payloads refer to IDs from the sequence discarded
        -- below. Remove them during the one-time cutover so those IDs cannot
        -- be mistaken for IDs from the new event sequence.
        DELETE FROM batch_change_agent_inbox_items
        WHERE kind IN ('workspace_changeset_hook_failed', 'workspace_changeset_hook_succeeded');

        EXECUTE $query$
            DELETE FROM executor_job_tokens AS tokens
            USING batch_spec_workspace_execution_jobs AS jobs
            WHERE jobs.changeset_hook_job_id IS NOT NULL
              AND tokens.tenant_id = jobs.tenant_id
              AND tokens.job_id = jobs.id
              AND tokens.queue = 'batches'
        $query$;

        EXECUTE $query$
            DELETE FROM batch_spec_workspace_execution_jobs
            WHERE changeset_hook_job_id IS NOT NULL
        $query$;
    END IF;
END;
$$;

-- Old pods still select this column and its ranked view during a rolling
-- upgrade, so keep the compatibility shape until every supported downgrade
-- path no longer needs it. New code does not read the discriminator, and the
-- constraint prevents an old worker from creating a hook-backed workspace job
-- that new code could mistake for an ordinary workspace execution.
DROP INDEX IF EXISTS batch_spec_workspace_execution_jobs_changeset_hook_job_id;
ALTER TABLE batch_spec_workspace_execution_jobs
    DROP CONSTRAINT IF EXISTS batch_spec_workspace_execution_jobs_no_legacy_hook_jobs;
ALTER TABLE batch_spec_workspace_execution_jobs
    ADD CONSTRAINT batch_spec_workspace_execution_jobs_no_legacy_hook_jobs
    CHECK (changeset_hook_job_id IS NULL) NOT VALID;
COMMENT ON COLUMN batch_spec_workspace_execution_jobs.changeset_hook_job_id IS
    'Deprecated read-compatible column retained for mixed-version rollouts; new non-null values are rejected. Drop after Sourcegraph 8.0.';

-- Old pods also keep using the legacy hook queue during a rolling upgrade.
-- Discard pre-cutover work, but retain the empty compatibility table so those
-- pods continue to function until the rollout completes.
DELETE FROM changeset_hook_jobs;
COMMENT ON TABLE changeset_hook_jobs IS
    'Deprecated compatibility table retained for mixed-version rollouts. Drop after Sourcegraph 8.0.';
