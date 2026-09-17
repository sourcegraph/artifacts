-- A follow-up commit is superseded when its stored diff no longer applies to the
-- changeset branch head (most often because an external push moved the branch after
-- the diff was computed, but also when it conflicts with an earlier follow-up in
-- the same chain). Superseded follow-ups are terminal: the reconciler never pushes
-- them. If the triggering condition persists, a later successful code-host sync
-- can enqueue a new hook run against the updated head, subject to its attempt cap.
ALTER TABLE changeset_followup_commits
    ADD COLUMN IF NOT EXISTS superseded_at timestamp with time zone,
    ADD COLUMN IF NOT EXISTS superseded_reason text;

-- Keep superseded_at and superseded_reason in lockstep, matching
-- changeset_followup_commits_pushed_fields_consistent.
ALTER TABLE changeset_followup_commits
    DROP CONSTRAINT IF EXISTS changeset_followup_commits_superseded_fields_consistent,
    ADD CONSTRAINT changeset_followup_commits_superseded_fields_consistent CHECK (
        (superseded_at IS NULL AND superseded_reason IS NULL)
        OR (superseded_at IS NOT NULL AND superseded_reason IS NOT NULL AND superseded_reason <> '')
    ),
    DROP CONSTRAINT IF EXISTS changeset_followup_commits_terminal_state_consistent,
    ADD CONSTRAINT changeset_followup_commits_terminal_state_consistent CHECK (
        pushed_commit_sha IS NULL OR superseded_at IS NULL
    );

-- The reconciler treats a follow-up as "unpushed" only when it is neither pushed
-- nor superseded. Narrow the partial index to match so it keeps serving the
-- unpushed lookup after the new state is introduced.
DROP INDEX IF EXISTS changeset_followup_commits_unpushed;

CREATE INDEX IF NOT EXISTS changeset_followup_commits_unpushed
    ON changeset_followup_commits
    USING btree (tenant_id, changeset_id, ordinal)
    WHERE (pushed_commit_sha IS NULL AND superseded_at IS NULL);
