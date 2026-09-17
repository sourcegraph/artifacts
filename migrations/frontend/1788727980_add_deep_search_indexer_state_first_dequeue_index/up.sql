CREATE INDEX CONCURRENTLY IF NOT EXISTS deepsearch_search_queue_dequeue_filter_idx
    ON deepsearch_search_queue (state, process_after, queued_at, id, tenant_id)
    INCLUDE (finished_at)
    WHERE state IN ('queued', 'errored');
