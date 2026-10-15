CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS changeset_jobs_reconciling_publication_outcome
ON changeset_jobs (tenant_id, changeset_id)
WHERE publication_outcome_state = 'reconciling';
