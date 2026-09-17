CREATE INDEX CONCURRENTLY IF NOT EXISTS diff_tours_dequeue_filter_idx
    ON diff_tours (state, process_after, queued_at, id, tenant_id)
    INCLUDE (finished_at)
    WHERE state IN ('queued', 'errored');
