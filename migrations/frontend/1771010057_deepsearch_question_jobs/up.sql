CREATE TABLE IF NOT EXISTS deepsearch_question_jobs (
    id BIGSERIAL PRIMARY KEY,
    question_id INTEGER NOT NULL REFERENCES deepsearch_questions(id) ON DELETE CASCADE,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,

    -- Standard workerutil columns
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

ALTER TABLE deepsearch_question_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_question_jobs;
CREATE POLICY tenant_isolation_policy ON deepsearch_question_jobs
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant)
    );

CREATE INDEX IF NOT EXISTS deepsearch_question_jobs_dequeue_idx
    ON deepsearch_question_jobs USING btree (tenant_id, state, process_after, queued_at, id)
    WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));
CREATE INDEX IF NOT EXISTS deepsearch_question_jobs_question_id_idx ON deepsearch_question_jobs (question_id);
