CREATE INDEX CONCURRENTLY IF NOT EXISTS external_service_sync_jobs_dequeue_order_idx
ON external_service_sync_jobs (process_after, id)
WHERE state = 'queued';
