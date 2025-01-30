ALTER TABLE lsif_indexes
ADD COLUMN IF NOT EXISTS matched_policy_id integer;
-- matched_policy_id is nullable because:
-- 1. For already queued jobs at the time of this migration,
--    we don't know which policy triggered this job to be enqueued.
-- 2. We want to be able to put a foreign key from this column to
--    lsif_configuration_policies.id but on policy deletion, we can give the
--    site admin to keep the old jobs if needed.

COMMENT ON COLUMN lsif_indexes.matched_policy_id IS 'The policy ID that triggered this indexing job to be created.';

DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_constraint
                            WHERE conname = 'lsif_indexes_matched_policy_id_fkey') THEN
        ALTER TABLE lsif_indexes
            ADD CONSTRAINT lsif_indexes_matched_policy_id_fkey FOREIGN KEY
                (matched_policy_id) REFERENCES lsif_configuration_policies (id)
                ON DELETE RESTRICT;
        -- Use ON DELETE RESTRICT to defer decision of cascade deletion vs
        -- setting to NULL to the Go code.
    END IF;
END$$;

-- For rows with explicit match tracking, there should be at most one queued job
-- for a given (repo, commit, indexer, root) and the caller needs to decide if
-- that should be overwritten, or kept as-is.
--
-- The column ordering in the index puts commit last so that we can potentially
-- query for conflicting rows in a CTE based on (repo, indexer, root, tenant_id).
CREATE UNIQUE INDEX IF NOT EXISTS lsif_indexes_queued_partial_ukey
    ON lsif_indexes (repository_id, indexer, root, tenant_id, commit)
    WHERE state = 'queued' AND matched_policy_id IS NOT NULL;

COMMENT ON INDEX lsif_indexes_queued_partial_ukey IS
    'Partial index for commit overwriting on detecting new commits for a repository'
    ' while the old commit is still enqueued.';

CREATE INDEX IF NOT EXISTS lsif_indexes_matched_policy_id_partial_idx
    ON lsif_indexes (matched_policy_id)
    WHERE matched_policy_id IS NOT NULL;

COMMENT ON INDEX lsif_indexes_matched_policy_id_partial_idx IS
    'Inverted index for FK constraint to support policy deletion without a full table scan.';

ALTER TABLE lsif_indexes
ADD COLUMN IF NOT EXISTS matched_revision TEXT;
-- matched_revision is nullable because we don't know which revision was matched
-- for already queued jobs at the time of this migration.

COMMENT ON COLUMN lsif_indexes.matched_revision IS
    'The revision that triggered this indexing job to be created.'
    ' Depending on matched_policy_id, this may be a tag name, a branch name, or HEAD.';
