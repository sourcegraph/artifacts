CREATE INDEX CONCURRENTLY IF NOT EXISTS changeset_sync_jobs_dequeue_active_order_idx
    ON changeset_sync_jobs (priority DESC, COALESCE(process_after, queued_at), id)
    INCLUDE (state, process_after, finished_at)
    WHERE state IN ('queued', 'errored');
