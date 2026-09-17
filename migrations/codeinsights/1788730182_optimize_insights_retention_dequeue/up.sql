CREATE INDEX CONCURRENTLY IF NOT EXISTS insights_data_retention_jobs_dequeue_order_idx
ON insights_data_retention_jobs (queued_at, id)
INCLUDE (state, process_after, finished_at)
WHERE state IN ('queued', 'errored');
