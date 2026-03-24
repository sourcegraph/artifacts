DROP INDEX IF EXISTS permission_sync_jobs_unique_user;
DROP INDEX IF EXISTS permission_sync_jobs_unique_repo;

CREATE UNIQUE INDEX IF NOT EXISTS permission_sync_jobs_unique
    ON permission_sync_jobs USING btree (priority, user_id, repository_id, cancel, process_after, tenant_id)
    WHERE (state = 'queued'::text);
