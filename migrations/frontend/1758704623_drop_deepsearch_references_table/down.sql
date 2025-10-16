CREATE TABLE IF NOT EXISTS deepsearch_references(
    id serial PRIMARY KEY,
    conversation_id integer NOT NULL REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant') ::integer,
    repo_id integer REFERENCES repo(id) ON DELETE SET NULL,
    file_path text NOT NULL DEFAULT '',
    created_at timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT deepsearch_references_repo_filepath_unique UNIQUE (conversation_id, repo_id, file_path)
);

COMMENT ON COLUMN deepsearch_references.file_path IS 'File path can be empty because some agent tools only produce repo or commit information but not file content. We use empty string as the sentinel value so that the unique constraint works correctly';

ALTER TABLE deepsearch_references ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_references;

CREATE POLICY tenant_isolation_policy ON deepsearch_references AS PERMISSIVE
    FOR ALL TO PUBLIC
        USING ((tenant_id =(
            SELECT
                (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
