-- Drop the unique index for HEAD revisions with matched policies
DROP INDEX IF EXISTS lsif_indexes_queued_head_policy_partial_ukey;
