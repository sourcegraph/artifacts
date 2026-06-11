CREATE TABLE IF NOT EXISTS changeset_spec_commits (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    changeset_spec_id BIGINT NOT NULL REFERENCES changeset_specs(id) ON DELETE CASCADE DEFERRABLE,
    ordinal INTEGER NOT NULL,
    diff BYTEA,
    commit_message TEXT,
    commit_author_name TEXT,
    commit_author_email TEXT,
    expected_parent_sha TEXT,
    resulting_commit_sha TEXT,
    resulting_head_sha TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE changeset_spec_commits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON changeset_spec_commits;
CREATE POLICY tenant_isolation_policy ON changeset_spec_commits AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

CREATE UNIQUE INDEX IF NOT EXISTS changeset_spec_commits_unique_spec_ordinal_idx
    ON changeset_spec_commits (tenant_id, changeset_spec_id, ordinal);

CREATE INDEX IF NOT EXISTS changeset_spec_commits_changeset_spec_id_idx
    ON changeset_spec_commits (changeset_spec_id, tenant_id);
