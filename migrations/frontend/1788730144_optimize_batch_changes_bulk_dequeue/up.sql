CREATE INDEX CONCURRENTLY IF NOT EXISTS changeset_jobs_dequeue_order_idx
ON changeset_jobs ((state = 'errored'), updated_at DESC, id)
INCLUDE (process_after, finished_at)
WHERE state IN ('queued', 'errored');
