CREATE TABLE IF NOT EXISTS batch_change_agents (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    owner_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT '',
    -- rand_id is a stable, non-enumerable public identifier for the agent.
    -- It is used to derive externally-visible names (for example the
    -- materialized batch change name) so that those names do not expose the
    -- agent's serial primary key. Unlike read_token it is not rotatable.
    rand_id UUID NOT NULL DEFAULT gen_random_uuid(),
    -- read_token is a rotatable token used for read-only downstream access
    -- (for example SSE stream snapshots and shared read endpoints consumed by
    -- AgentThread-style clients). It is intentionally separate from id so it
    -- can be rotated without affecting the stable identifier of the agent.
    read_token UUID NOT NULL DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN batch_change_agents.rand_id IS
    'Stable, non-enumerable public identifier used to derive externally-visible names (e.g. the materialized batch change name).';

COMMENT ON COLUMN batch_change_agents.read_token IS
    'Rotatable token granting read-only downstream access (e.g. SSE stream snapshots and shared read endpoints).';

CREATE TABLE IF NOT EXISTS batch_change_agent_threads (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    agent_id INTEGER NOT NULL REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS batch_change_agent_messages (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    thread_id INTEGER NOT NULL REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,
    sequence INTEGER NOT NULL,
    question TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'processing',
    answer TEXT,
    error TEXT,
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_messages_status_check CHECK (status IN ('processing', 'completed', 'cancelled', 'failed')),
    CONSTRAINT batch_change_agent_messages_sequence_check CHECK (sequence > 0)
);

CREATE TABLE IF NOT EXISTS batch_change_agent_turns (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    message_id INTEGER NOT NULL REFERENCES batch_change_agent_messages(id) ON DELETE CASCADE,
    sequence INTEGER NOT NULL,
    role TEXT NOT NULL,
    content JSONB NOT NULL DEFAULT '[]'::jsonb,
    reasoning TEXT NOT NULL DEFAULT '',
    tool_calls JSONB NOT NULL DEFAULT '[]'::jsonb,
    tool_results JSONB NOT NULL DEFAULT '[]'::jsonb,
    error JSONB,
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_turns_role_check CHECK (role IN ('system', 'user', 'assistant', 'tool')),
    CONSTRAINT batch_change_agent_turns_sequence_check CHECK (sequence > 0)
);

COMMENT ON COLUMN batch_change_agent_turns.content IS
    'Ordered structured content blocks for the turn (text or image blocks), encoded as a JSON array matching the BatchChangeAgentMessageContentBlock GraphQL union.';

CREATE TABLE IF NOT EXISTS batch_change_agent_jobs (
    id BIGSERIAL PRIMARY KEY,
    message_id INTEGER NOT NULL REFERENCES batch_change_agent_messages(id) ON DELETE CASCADE,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,

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

-- TODO(batchchanges-v3): batch_change_agent_spec_drafts is intended to back
-- the draft -> approval -> submit-with-token flow so we can preserve spec
-- history when the materialized batch_specs row is clobbered. Revisit (and
-- possibly drop) once the approval flow is wired up end to end.
CREATE TABLE IF NOT EXISTS batch_change_agent_spec_drafts (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    agent_id INTEGER NOT NULL REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    thread_id INTEGER REFERENCES batch_change_agent_threads(id) ON DELETE SET NULL,
    message_id INTEGER REFERENCES batch_change_agent_messages(id) ON DELETE SET NULL,
    version INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'draft',
    raw_spec TEXT NOT NULL DEFAULT '',
    spec_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    materialized_batch_spec_id BIGINT REFERENCES batch_specs(id) ON DELETE SET NULL,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_spec_drafts_status_check CHECK (status IN ('draft', 'materialized', 'failed', 'archived')),
    CONSTRAINT batch_change_agent_spec_drafts_version_check CHECK (version > 0)
);

ALTER TABLE batch_changes
    ADD COLUMN IF NOT EXISTS agent_id INTEGER REFERENCES batch_change_agents(id) ON DELETE SET NULL;

ALTER TABLE batch_change_agents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agents;
CREATE POLICY tenant_isolation_policy ON batch_change_agents AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE batch_change_agent_threads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_threads;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_threads AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE batch_change_agent_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_messages;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_messages AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE batch_change_agent_turns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_turns;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_turns AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE batch_change_agent_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_jobs;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant)
    );

ALTER TABLE batch_change_agent_spec_drafts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_spec_drafts;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_spec_drafts AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

-- Unique indexes keep tenant_id leading because uniqueness must be scoped per
-- tenant. Non-unique indexes put tenant_id last because we don't filter by
-- tenant_id outside of MTSG, so a leading tenant_id column would only hurt
-- selectivity.
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agents_tenant_rand_id_idx
    ON batch_change_agents (tenant_id, rand_id);
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agents_tenant_read_token_idx
    ON batch_change_agents (tenant_id, read_token);
CREATE INDEX IF NOT EXISTS batch_change_agents_owner_created_idx
    ON batch_change_agents (owner_user_id, created_at DESC, id DESC, tenant_id);

CREATE INDEX IF NOT EXISTS batch_change_agent_threads_agent_updated_idx
    ON batch_change_agent_threads (agent_id, updated_at DESC, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_messages_thread_sequence_idx
    ON batch_change_agent_messages (tenant_id, thread_id, sequence);
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_messages_one_processing_idx
    ON batch_change_agent_messages (tenant_id, thread_id)
    WHERE status = 'processing';
CREATE INDEX IF NOT EXISTS batch_change_agent_messages_thread_id_idx
    ON batch_change_agent_messages (thread_id, id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_turns_message_sequence_idx
    ON batch_change_agent_turns (tenant_id, message_id, sequence);
CREATE INDEX IF NOT EXISTS batch_change_agent_turns_message_id_idx
    ON batch_change_agent_turns (message_id, id, tenant_id);

CREATE INDEX IF NOT EXISTS batch_change_agent_jobs_dequeue_idx
    ON batch_change_agent_jobs USING btree (state, process_after, queued_at, id, tenant_id)
    WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));
CREATE INDEX IF NOT EXISTS batch_change_agent_jobs_message_id_idx
    ON batch_change_agent_jobs (message_id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS batch_changes_one_active_agent_idx
    ON batch_changes (tenant_id, agent_id)
    WHERE agent_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_spec_drafts_agent_version_idx
    ON batch_change_agent_spec_drafts (tenant_id, agent_id, version);
CREATE INDEX IF NOT EXISTS batch_change_agent_spec_drafts_thread_id_idx
    ON batch_change_agent_spec_drafts (thread_id, tenant_id);
CREATE INDEX IF NOT EXISTS batch_change_agent_spec_drafts_message_id_idx
    ON batch_change_agent_spec_drafts (message_id, tenant_id);
CREATE INDEX IF NOT EXISTS batch_change_agent_spec_drafts_materialized_idx
    ON batch_change_agent_spec_drafts (materialized_batch_spec_id, tenant_id);
