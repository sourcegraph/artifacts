-- Create new index that excludes re-queued jobs (num_resets > 0)
-- This prevents ResetStalled from failing when a new job was enqueued
-- while an existing job was stalled in 'processing' state
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS lsif_indexes_queued_partial_ukey
ON lsif_indexes (repository_id, indexer, root, tenant_id, commit)
WHERE state = 'queued'
  AND matched_policy_id IS NOT NULL
  AND num_resets = 0;
