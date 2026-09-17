CREATE INDEX CONCURRENTLY IF NOT EXISTS deepsearch_question_jobs_dequeue_filter_idx
    ON deepsearch_question_jobs (state, process_after, queued_at, id, tenant_id)
    INCLUDE (finished_at)
    WHERE state IN ('queued', 'errored');
