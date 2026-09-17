-- Match the single-tenant dequeue ordering without leading on tenant_id.
CREATE INDEX CONCURRENTLY IF NOT EXISTS batch_change_agent_jobs_dequeue_order_idx
    ON batch_change_agent_jobs (queued_at, id)
    INCLUDE (state, process_after, finished_at)
    WHERE state IN ('queued', 'errored');
