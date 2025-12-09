-- Create unique index to prevent duplicate queued jobs for HEAD revisions with matched policies
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS lsif_indexes_queued_head_policy_partial_ukey
ON lsif_indexes (repository_id, indexer, root, tenant_id)
WHERE state = 'queued'::text
  AND matched_policy_id IS NOT NULL
  AND matched_revision = 'HEAD';
