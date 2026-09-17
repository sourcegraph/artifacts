CREATE INDEX CONCURRENTLY IF NOT EXISTS insights_background_jobs_dequeue_order_idx
ON insights_background_jobs (id)
INCLUDE (backfill_id, process_after, finished_at)
WHERE state IN ('queued', 'errored');
