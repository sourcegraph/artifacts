CREATE INDEX CONCURRENTLY IF NOT EXISTS cm_action_jobs_dequeue_order_idx
    ON cm_action_jobs (id)
    INCLUDE (process_after, finished_at)
    WHERE state IN ('queued', 'errored');
