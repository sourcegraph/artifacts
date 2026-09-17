CREATE INDEX CONCURRENTLY IF NOT EXISTS permission_sync_jobs_repo_dequeue_order_idx
ON permission_sync_jobs (priority DESC, process_after ASC NULLS FIRST, id)
WHERE state = 'queued' AND repository_id IS NOT NULL;
