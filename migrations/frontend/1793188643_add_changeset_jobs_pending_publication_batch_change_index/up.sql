CREATE INDEX CONCURRENTLY IF NOT EXISTS changeset_jobs_pending_publication_batch_change
    ON changeset_jobs (tenant_id, batch_change_id)
    WHERE publication_outcome_state IN ('pending', 'reconciling');
