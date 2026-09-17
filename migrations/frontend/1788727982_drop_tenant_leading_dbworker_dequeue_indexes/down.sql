-- Restore the original tenant-leading indexes on rollback.
CREATE INDEX IF NOT EXISTS diff_tours_dequeue_idx
    ON diff_tours (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

CREATE INDEX IF NOT EXISTS deepsearch_question_jobs_dequeue_idx
    ON deepsearch_question_jobs (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

CREATE INDEX IF NOT EXISTS deepsearch_search_queue_dequeue_idx
    ON deepsearch_search_queue (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');
