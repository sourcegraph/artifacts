CREATE INDEX CONCURRENTLY IF NOT EXISTS repo_activity_graph_jobs_v2_dequeue_queued_at_idx
ON repo_activity_graph_jobs_v2 (queued_at, id)
INCLUDE (process_after, finished_at)
WHERE state IN ('queued', 'errored');
