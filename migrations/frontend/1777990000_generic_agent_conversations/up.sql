CREATE TABLE IF NOT EXISTS generic_agent_conversations (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS generic_agent_questions (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    conversation_id INTEGER NOT NULL REFERENCES generic_agent_conversations(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'processing',
    answer TEXT NOT NULL DEFAULT '',
    error TEXT NOT NULL DEFAULT '',
    messages JSONB NOT NULL DEFAULT '[]'::jsonb,
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS generic_agent_question_jobs (
    id BIGSERIAL PRIMARY KEY,
    question_id INTEGER NOT NULL REFERENCES generic_agent_questions(id) ON DELETE CASCADE,
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

ALTER TABLE generic_agent_conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON generic_agent_conversations;
CREATE POLICY tenant_isolation_policy ON generic_agent_conversations AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE generic_agent_questions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON generic_agent_questions;
CREATE POLICY tenant_isolation_policy ON generic_agent_questions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

ALTER TABLE generic_agent_question_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON generic_agent_question_jobs;
CREATE POLICY tenant_isolation_policy ON generic_agent_question_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant)
    );

CREATE INDEX IF NOT EXISTS generic_agent_conversations_user_updated_at_idx
    ON generic_agent_conversations (tenant_id, user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS generic_agent_questions_conversation_id_idx
    ON generic_agent_questions (tenant_id, conversation_id, id);
CREATE INDEX IF NOT EXISTS generic_agent_question_jobs_dequeue_idx
    ON generic_agent_question_jobs USING btree (tenant_id, state, process_after, queued_at, id)
    WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));
CREATE INDEX IF NOT EXISTS generic_agent_question_jobs_question_id_idx
    ON generic_agent_question_jobs (tenant_id, question_id);
