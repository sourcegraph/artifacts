CREATE INDEX CONCURRENTLY IF NOT EXISTS batch_spec_resolution_jobs_dequeue_order_idx
ON batch_spec_resolution_jobs ((state = 'errored'), updated_at DESC, id)
INCLUDE (process_after, finished_at)
WHERE state IN ('queued', 'errored');
