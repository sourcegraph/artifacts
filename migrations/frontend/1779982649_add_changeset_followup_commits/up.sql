CREATE TABLE IF NOT EXISTS changeset_followup_commits (
    id bigserial PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,
    changeset_id bigint NOT NULL REFERENCES changesets(id) ON DELETE CASCADE DEFERRABLE,
    ordinal integer NOT NULL,
    diff bytea NOT NULL,
    diff_stat_added integer,
    diff_stat_deleted integer,
    commit_message text NOT NULL,
    commit_author_name text,
    commit_author_email text,
    pushed_commit_sha text,
    pushed_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT changeset_followup_commits_ordinal_positive
        CHECK (ordinal > 0),
    CONSTRAINT changeset_followup_commits_pushed_fields_consistent
        CHECK (
            (pushed_commit_sha IS NULL AND pushed_at IS NULL)
            OR
            (pushed_commit_sha IS NOT NULL AND pushed_commit_sha <> '' AND pushed_at IS NOT NULL)
        )
);

CREATE UNIQUE INDEX IF NOT EXISTS changeset_followup_commits_changeset_id_ordinal
    ON changeset_followup_commits (tenant_id, changeset_id, ordinal);

-- Supports the reconciler scan for unpushed follow-ups on a changeset,
-- preserving ordinal order under RLS without an extra sort.
CREATE INDEX IF NOT EXISTS changeset_followup_commits_unpushed
    ON changeset_followup_commits (tenant_id, changeset_id, ordinal)
    WHERE pushed_commit_sha IS NULL;

ALTER TABLE changeset_followup_commits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON changeset_followup_commits;
CREATE POLICY tenant_isolation_policy ON changeset_followup_commits AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
