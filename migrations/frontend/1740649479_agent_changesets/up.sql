-- Perform migration here.
--
-- See /migrations/README.md. Highlights:
--  * Make migrations idempotent (use IF EXISTS)
--  * Make migrations backwards-compatible (old readers/writers must continue to work)
--  * If you are using CREATE INDEX CONCURRENTLY, then make sure that only one statement
--    is defined per file, and that each such statement is NOT wrapped in a transaction.
--    Each such migration must also declare "createIndexConcurrently: true" in their
--    associated metadata.yaml file.
--  * If you are modifying Postgres extensions, you must also declare "privileged: true"
--    in the associated metadata.yaml file.
--  * If you are inserting data, ensure your table is marked as a data table and that it
--    inserts for all tenants.

CREATE TABLE IF NOT EXISTS agent_changesets (
    id SERIAL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    data jsonb,
    repo_id INTEGER GENERATED ALWAYS AS ((data->>'repo_id')::integer) STORED REFERENCES repo(id),
    pull_number INTEGER GENERATED ALWAYS AS ((data->>'pull_number')::integer) STORED,
    github_app_installation_id INTEGER GENERATED ALWAYS AS ((data->>'github_app_installation_id')::integer) STORED,
    external_service_type TEXT GENERATED ALWAYS AS ((data->>'external_service_type')::text) STORED,
    external_user_html_url TEXT GENERATED ALWAYS AS ((data->>'external_user_html_url')::text) STORED,
    external_service_id TEXT GENERATED ALWAYS AS ((data->>'external_service_id')::text) STORED NOT NULL,
    CONSTRAINT unique_external_service_id UNIQUE (external_service_id, tenant_id),
    CONSTRAINT check_external_service_type CHECK (external_service_type IN ('github', 'gitlab'))
);

ALTER TABLE agent_changesets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_changesets;
CREATE POLICY tenant_isolation_policy ON agent_changesets AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

COMMENT ON TABLE agent_changesets IS 'A changeset is essentially a GitHub pull request or GitLab merge request. '
  'Note that Batch Changes has similar tables to track changesets, but intentionally have a separate table '
  'to maximize product velocity and minimize risk of unintended regressions.';

CREATE INDEX IF NOT EXISTS idx_agent_changesets_external_user_html_url ON agent_changesets (external_user_html_url);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_external_service_type ON agent_changesets (external_service_type);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_github_app_installation_id ON agent_changesets (github_app_installation_id);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_repo_id ON agent_changesets (repo_id);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_pull_number ON agent_changesets (pull_number);


CREATE OR REPLACE FUNCTION update_agent_changesets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_agent_changesets_updated_at
    BEFORE UPDATE ON agent_changesets
    FOR EACH ROW
    EXECUTE FUNCTION update_agent_changesets_updated_at();


CREATE TABLE IF NOT EXISTS agent_changeset_revisions (
    id SERIAL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    changeset_id INTEGER NOT NULL REFERENCES agent_changesets(id),
    base_oid TEXT NOT NULL,
    head_oid TEXT NOT NULL
);

COMMENT ON TABLE agent_changeset_revisions IS 'Reflects the head/base git revisions of a changeset at a given time. '
  'If you push a new commit then a new row is inserted with the new head/base revisions. '
  'This table allows us to precisely identify at what snapshot an agent review was run.';

ALTER TABLE agent_changeset_revisions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_changeset_revisions;
CREATE POLICY tenant_isolation_policy ON agent_changeset_revisions AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE INDEX IF NOT EXISTS idx_agent_changeset_branches_changeset_id ON agent_changeset_revisions (changeset_id);
