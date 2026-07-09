-- Durable batch change agent inbox: facts recorded while the agent is not
-- running a turn (for example a workspace execution failing after the
-- agent's turn ended), so the agent can discover them on a later turn.
CREATE TABLE IF NOT EXISTS batch_change_agent_inbox_items (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    agent_id INTEGER NOT NULL REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    thread_id INTEGER NOT NULL REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,
    kind TEXT NOT NULL,
    dedupe_key TEXT,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN batch_change_agent_inbox_items.dedupe_key IS
    'Optional stable producer-defined identity for facts that should create at most one inbox item. Deterministic, not a random request ID; leave it NULL for repeatable event occurrences.';

COMMENT ON COLUMN batch_change_agent_inbox_items.details IS
    'Typed per-kind payload: stable references and immutable facts about the event.';

-- Read cursor over the inbox, one row per agent/thread. The agent itself is
-- the only reader (via the read_inbox tool). If a future non-agent reader ever
-- needs its own process-once progress over this log, add a consumer_name
-- column with default 'agent' and widen the unique key -- a one-line migration.
CREATE TABLE IF NOT EXISTS batch_change_agent_inbox_cursors (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    agent_id INTEGER NOT NULL REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    thread_id INTEGER NOT NULL REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,
    last_read_item_id BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_inbox_cursors_agent_thread_unique
        UNIQUE (tenant_id, agent_id, thread_id)
);

COMMENT ON COLUMN batch_change_agent_inbox_cursors.last_read_item_id IS
    'Highest batch_change_agent_inbox_items.id the agent has read for the agent/thread. Never moves backwards.';

-- Records, on a message the system created to wake an idle agent, which inbox
-- fact kind triggered it (a batch_change_agent_inbox_items.kind value). NULL
-- means the message was not created by the wake dispatcher.
ALTER TABLE batch_change_agent_messages
    ADD COLUMN IF NOT EXISTS wake_kind TEXT;

-- dbworker queue of wake attempts. Recording a wake-worthy item inserts a wake
-- job in the same transaction; the wake dispatcher consumes these. Duplicate
-- wake jobs are harmless and are absorbed by the dispatcher.
CREATE TABLE IF NOT EXISTS batch_change_agent_wake_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    agent_id INTEGER NOT NULL REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    thread_id INTEGER NOT NULL REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,

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

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE batch_change_agent_inbox_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_inbox_items;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_inbox_items AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE batch_change_agent_inbox_cursors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_inbox_cursors;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_inbox_cursors AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE batch_change_agent_wake_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_wake_jobs;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_wake_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant)
    );

-- Unique indexes keep tenant_id leading because uniqueness must be scoped per
-- tenant. Non-unique indexes put tenant_id last because we don't filter by
-- tenant_id outside of MTSG, so a leading tenant_id column would only hurt
-- selectivity.

-- Producer dedupe is optional. Repeatable event kinds leave dedupe_key NULL
-- and can create multiple rows.
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_inbox_items_dedupe_key_idx
    ON batch_change_agent_inbox_items (tenant_id, agent_id, thread_id, kind, dedupe_key)
    WHERE dedupe_key IS NOT NULL;
-- Cursor reads (items for one thread after a cursor, in ID order) and
-- ON DELETE CASCADE support for the thread foreign key.
CREATE INDEX IF NOT EXISTS batch_change_agent_inbox_items_thread_id_idx
    ON batch_change_agent_inbox_items (thread_id, id, tenant_id);

-- Wake jobs are deliberately NOT coalesced by a partial unique index. Such an
-- index over the pending states would fight the dbworker state machine:
-- MarkErrored (processing -> errored) and ResetStalled (processing -> queued,
-- a single bulk UPDATE) are not constraint-aware, so a transition landing a row
-- on an already-pending (agent, thread) raises 23505 -- wedging that row and,
-- for the bulk reset, the whole tick. Duplicate wakes are harmless instead: the
-- dispatcher skips a wake whose inbox is already drained, and the
-- one-processing-message invariant serializes turns. See enqueueWakeJob.
CREATE INDEX IF NOT EXISTS batch_change_agent_wake_jobs_dequeue_idx
    ON batch_change_agent_wake_jobs USING btree (state, process_after, queued_at, id, tenant_id)
    WHERE state IN ('queued', 'errored');

-- ON DELETE CASCADE support for the thread foreign keys.
CREATE INDEX IF NOT EXISTS batch_change_agent_inbox_cursors_thread_id_idx
    ON batch_change_agent_inbox_cursors (thread_id, tenant_id);
CREATE INDEX IF NOT EXISTS batch_change_agent_wake_jobs_thread_id_idx
    ON batch_change_agent_wake_jobs (thread_id, tenant_id);
