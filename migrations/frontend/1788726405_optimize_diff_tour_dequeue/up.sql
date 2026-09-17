CREATE INDEX CONCURRENTLY IF NOT EXISTS diff_tours_dequeue_order_idx
    ON diff_tours (queued_at, id)
    INCLUDE (state, process_after, finished_at)
    WHERE state IN ('queued', 'errored');
