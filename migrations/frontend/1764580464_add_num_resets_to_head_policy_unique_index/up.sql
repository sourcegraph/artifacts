-- Drop the old index that doesn't account for num_resets
DROP INDEX IF EXISTS lsif_indexes_queued_head_policy_partial_ukey;
