CREATE INDEX CONCURRENTLY IF NOT EXISTS deepsearch_question_jobs_dequeue_order_idx
    ON deepsearch_question_jobs (queued_at, id)
    INCLUDE (state, process_after, finished_at)
    WHERE state IN ('queued', 'errored');
