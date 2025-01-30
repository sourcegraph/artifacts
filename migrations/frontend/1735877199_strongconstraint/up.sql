-- Syntactic indexing only allows HEAD policies; these constraints enforce that.
-- At the time of this migration (2025 Jan 3), syntactic indexing is not GA, so
-- it's fine to delete rows. See NOTE(id: syntactic-HEAD-only).

-- Perform deletions before introducing the corresponding constraints to
-- prevent failure when attempting to introduce the constraints.
-- These deletions are not for general cleanup.

-- Enforce that it is not possible to create non-HEAD policies
-- for syntactic indexing.
DELETE FROM lsif_configuration_policies
WHERE syntactic_indexing_enabled = true AND
      NOT (pattern = 'HEAD' AND type = 'GIT_COMMIT');

DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_constraint
                           WHERE conname = 'lsif_configuration_policies_syntactic_head_only_constraint') THEN
        ALTER TABLE lsif_configuration_policies
        ADD CONSTRAINT lsif_configuration_policies_syntactic_head_only_constraint
            CHECK (
                syntactic_indexing_enabled = false OR
                (pattern = 'HEAD' AND type = 'GIT_COMMIT')
            );
    END IF;
END$$;

-- For repositories which have more than one job, delete
-- all but the newest queued job.

DELETE FROM syntactic_scip_indexing_jobs j1
WHERE state = 'queued' AND EXISTS(
    SELECT 1
    FROM syntactic_scip_indexing_jobs j2
    WHERE j2.tenant_id = j1.tenant_id
        AND j2.repository_id = j1.repository_id
        AND j2.state = 'queued'
        AND (j2.queued_at > j1.queued_at -- prefer newer jobs over older ones
             OR (j2.queued_at = j1.queued_at AND j2.id > j1.id)) -- break ties
);

-- NOTE: We have an assertion based on this constraint in the
-- syntactic enqueuing logic; make sure to adjust that if this
-- constraint is ever removed or changed.

CREATE UNIQUE INDEX IF NOT EXISTS syntactic_scip_indexing_jobs_queued_partial_ukey
ON syntactic_scip_indexing_jobs (tenant_id, repository_id)
WHERE state = 'queued';
