CREATE INDEX CONCURRENTLY IF NOT EXISTS exhaustive_search_repo_revision_jobs_dequeue_order_idx
ON exhaustive_search_repo_revision_jobs ((state = 'errored'), updated_at DESC, id)
INCLUDE (process_after, finished_at)
WHERE state IN ('queued', 'errored');
