ALTER TABLE changeset_jobs
    ADD COLUMN IF NOT EXISTS initiated_by text CHECK (initiated_by IN ('user', 'agent'));

COMMENT ON COLUMN changeset_jobs.initiated_by IS 'Set iff a new job tracks a publication outcome: user or agent. NULL with a non-NULL publication_outcome_state identifies a UI job written by code that predates this column. NULL with no outcome state is untracked.';
COMMENT ON COLUMN changeset_jobs.publication_outcome_state IS 'Set on tracked publication jobs: pending until the job hands its changeset to the reconciler, reconciling while that reconcile is unfinished, done once its outcome is recorded or a newer spec takes the changeset away. NULL for untracked jobs.';

ALTER TABLE changesets
    ADD COLUMN IF NOT EXISTS agent_push_pending boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN changesets.agent_push_pending IS 'Whether a push an agent started on this changeset has not ended yet';
