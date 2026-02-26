-- Queue table for pending search indexing work at the question level
-- Triggers insert question IDs here; a background worker processes them
CREATE TABLE IF NOT EXISTS deepsearch_search_queue (
    id BIGSERIAL PRIMARY KEY,
    state TEXT NOT NULL DEFAULT 'queued',
    failure_message TEXT,
    queued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    process_after TIMESTAMPTZ,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMPTZ,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    cancel BOOLEAN NOT NULL DEFAULT false,
    question_id INTEGER NOT NULL REFERENCES deepsearch_questions(id) ON DELETE CASCADE,
    latest_question_updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    UNIQUE (tenant_id, question_id)
);

ALTER TABLE deepsearch_search_queue ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_search_queue;
CREATE POLICY tenant_isolation_policy ON deepsearch_search_queue AS PERMISSIVE FOR ALL TO PUBLIC
    USING (((SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text))
        OR (tenant_id = (SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE INDEX IF NOT EXISTS deepsearch_search_queue_dequeue_idx
    ON deepsearch_search_queue (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

-- Index table storing the search text per question
-- Allows direct linking to matching questions and O(1) updates per question change
CREATE TABLE IF NOT EXISTS deepsearch_search_index (
    question_id INTEGER NOT NULL REFERENCES deepsearch_questions(id) ON DELETE CASCADE,
    conversation_id INTEGER NOT NULL REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    search_text TEXT NOT NULL DEFAULT '',
    indexed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (tenant_id, question_id)
);

ALTER TABLE deepsearch_search_index ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_search_index;
CREATE POLICY tenant_isolation_policy ON deepsearch_search_index AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

-- Trigram index for fast ILIKE searches
CREATE INDEX IF NOT EXISTS deepsearch_search_index_search_text_trgm_idx
    ON deepsearch_search_index USING gin (search_text gin_trgm_ops);

-- Index for conversation lookup in search subquery
CREATE INDEX IF NOT EXISTS deepsearch_search_index_conversation_id_idx
    ON deepsearch_search_index (tenant_id, conversation_id);

-- Trigger function to enqueue question for search indexing
CREATE OR REPLACE FUNCTION deepsearch_enqueue_question_for_search()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW IS NOT NULL AND NEW.status != 'processing' THEN
        INSERT INTO deepsearch_search_queue (
            question_id,
            tenant_id,
            queued_at,
            process_after,
            latest_question_updated_at
        ) VALUES (
            NEW.id,
            NEW.tenant_id,
            now(),
            NULL,
            now()
        )
        ON CONFLICT (tenant_id, question_id) DO UPDATE SET
            latest_question_updated_at = EXCLUDED.latest_question_updated_at,
            queued_at = EXCLUDED.queued_at,
            process_after = EXCLUDED.process_after,
            state = 'queued',
            started_at = NULL,
            cancel = false;
    END IF;

    -- On DELETE, the CASCADE will clean up the index automatically
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger on questions: enqueue when questions are added or modified
DROP TRIGGER IF EXISTS deepsearch_questions_search_queue_trg ON deepsearch_questions;
CREATE TRIGGER deepsearch_questions_search_queue_trg
    AFTER INSERT OR UPDATE ON deepsearch_questions
    FOR EACH ROW EXECUTE FUNCTION deepsearch_enqueue_question_for_search();

-- Backfill: enqueue all existing questions for indexing
INSERT INTO deepsearch_search_queue (question_id, tenant_id, queued_at, latest_question_updated_at)
SELECT q.id, q.tenant_id, now(), now()
FROM deepsearch_questions q
ON CONFLICT (tenant_id, question_id) DO NOTHING;
