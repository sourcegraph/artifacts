DROP INDEX IF EXISTS changeset_followup_commits_unpushed;

CREATE INDEX IF NOT EXISTS changeset_followup_commits_unpushed
    ON changeset_followup_commits
    USING btree (tenant_id, changeset_id, ordinal)
    WHERE (pushed_commit_sha IS NULL);

ALTER TABLE changeset_followup_commits
    DROP CONSTRAINT IF EXISTS changeset_followup_commits_terminal_state_consistent,
    DROP CONSTRAINT IF EXISTS changeset_followup_commits_superseded_fields_consistent;

ALTER TABLE changeset_followup_commits
    DROP COLUMN IF EXISTS superseded_reason,
    DROP COLUMN IF EXISTS superseded_at;
