ALTER TABLE changesets DROP COLUMN IF EXISTS agent_push_pending;
ALTER TABLE changeset_jobs DROP COLUMN IF EXISTS initiated_by;

COMMENT ON COLUMN changeset_jobs.publication_outcome_state IS 'Set on direct UI publication jobs: pending until the job hands its changeset to the reconciler, reconciling while that reconcile is unfinished, done once its outcome is recorded or a newer spec takes the changeset away. NULL for other jobs.';
