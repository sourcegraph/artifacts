CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS permission_sync_jobs_unique_user
    ON permission_sync_jobs USING btree (priority, user_id, cancel, tenant_id)
    WHERE state = 'queued'::text AND user_id IS NOT NULL AND num_resets = 0;
