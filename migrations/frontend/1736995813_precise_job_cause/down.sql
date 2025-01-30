ALTER TABLE lsif_indexes
    DROP COLUMN IF EXISTS matched_revision;

DROP INDEX IF EXISTS lsif_indexes_matched_policy_id_partial_idx;

DROP INDEX IF EXISTS lsif_indexes_queued_partial_ukey;

ALTER TABLE lsif_indexes
    DROP CONSTRAINT IF EXISTS lsif_indexes_matched_policy_id_fkey;

ALTER TABLE lsif_indexes
    DROP COLUMN IF EXISTS matched_policy_id;
