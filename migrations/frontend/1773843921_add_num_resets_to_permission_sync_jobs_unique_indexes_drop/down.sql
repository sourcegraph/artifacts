CREATE UNIQUE INDEX IF NOT EXISTS permission_sync_jobs_unique_user
    ON permission_sync_jobs USING btree (priority, user_id, cancel, tenant_id)
    WHERE state = 'queued'::text AND user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS permission_sync_jobs_unique_repo
    ON permission_sync_jobs USING btree (priority, repository_id, cancel, tenant_id)
    WHERE state = 'queued'::text AND repository_id IS NOT NULL;
