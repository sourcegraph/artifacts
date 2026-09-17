CREATE INDEX CONCURRENTLY IF NOT EXISTS deepsearch_search_queue_dequeue_order_idx
    ON deepsearch_search_queue (process_after NULLS FIRST, queued_at, id)
    INCLUDE (state, finished_at)
    WHERE state IN ('queued', 'errored');
