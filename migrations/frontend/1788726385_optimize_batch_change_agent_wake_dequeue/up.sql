CREATE INDEX CONCURRENTLY IF NOT EXISTS batch_change_agent_wake_jobs_dequeue_order_idx
    ON batch_change_agent_wake_jobs (queued_at, id)
    INCLUDE (state, process_after, finished_at)
    WHERE state IN ('queued', 'errored');
