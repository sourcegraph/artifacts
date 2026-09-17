CREATE INDEX CONCURRENTLY IF NOT EXISTS bitbucket_project_permissions_dequeue_order_idx
    ON explicit_permissions_bitbucket_projects_jobs (id)
    INCLUDE (process_after, finished_at)
    WHERE state IN ('queued', 'errored');
