-- The previous version used `NEW IS NOT NULL` as a guard, but on a composite
-- row that expression is FALSE when any column is NULL (Postgres row-null
-- semantics), so questions with NULL intents/topics were silently skipped.
-- The trigger only fires on INSERT/UPDATE, so NEW is always non-null; drop
-- the guard entirely.
CREATE OR REPLACE FUNCTION deepsearch_enqueue_question_for_search()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status != 'processing' THEN
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

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Clear the queue and re-enqueue from scratch. The queue is an ephemeral
-- workqueue, so truncating is cheaper than INSERT ... ON CONFLICT DO UPDATE
-- and avoids leaving stale rows from the buggy trigger behind.
TRUNCATE TABLE deepsearch_search_queue;

INSERT INTO deepsearch_search_queue (question_id, tenant_id, queued_at, latest_question_updated_at)
SELECT q.id, q.tenant_id, now(), now()
FROM deepsearch_questions q
WHERE q.status IS DISTINCT FROM 'processing';
