ALTER TABLE changeset_jobs
    ADD COLUMN IF NOT EXISTS publication_outcome_state TEXT CHECK (publication_outcome_state IN ('pending', 'reconciling', 'done'));

COMMENT ON COLUMN changeset_jobs.publication_outcome_state IS 'Set on direct UI publication jobs: pending until the job hands its changeset to the reconciler, reconciling while that reconcile is unfinished, done once its outcome is recorded or a newer spec takes the changeset away. NULL for other jobs.';
