-- Create new index that excludes re-queued jobs (num_resets > 0)
-- This prevents ResetStalled from failing when a new HEAD job was enqueued
-- while an existing job was stalled in 'processing' state
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS lsif_indexes_queued_head_policy_partial_ukey
ON lsif_indexes (repository_id, indexer, root, tenant_id)
WHERE state = 'queued'
  AND matched_policy_id IS NOT NULL
  AND matched_revision = 'HEAD'
  AND num_resets = 0;
