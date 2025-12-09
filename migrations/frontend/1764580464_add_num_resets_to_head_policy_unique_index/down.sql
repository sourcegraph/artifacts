-- Restore the original index without num_resets condition
CREATE UNIQUE INDEX IF NOT EXISTS lsif_indexes_queued_head_policy_partial_ukey
ON lsif_indexes (repository_id, indexer, root, tenant_id)
WHERE state = 'queued'
  AND matched_policy_id IS NOT NULL
  AND matched_revision = 'HEAD';
