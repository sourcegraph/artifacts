CREATE INDEX CONCURRENTLY IF NOT EXISTS outbound_webhook_jobs_dequeue_order_idx
    ON outbound_webhook_jobs (id)
    INCLUDE (process_after, finished_at)
    WHERE state IN ('queued', 'errored');
