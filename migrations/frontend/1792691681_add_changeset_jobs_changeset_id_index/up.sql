CREATE INDEX CONCURRENTLY IF NOT EXISTS changeset_jobs_changeset_id_idx
    ON changeset_jobs (tenant_id, changeset_id, id DESC);
