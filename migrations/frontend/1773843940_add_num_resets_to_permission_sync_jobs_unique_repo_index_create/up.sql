CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS permission_sync_jobs_unique_repo
    ON permission_sync_jobs USING btree (priority, repository_id, cancel, tenant_id)
    WHERE state = 'queued'::text AND repository_id IS NOT NULL AND num_resets = 0;
