CREATE TABLE IF NOT EXISTS diff_file_viewed_states (
    tenant_id     INTEGER     NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,
    user_id       INTEGER     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    repo_id       INTEGER     NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    base_ref      TEXT        NOT NULL,
    head_ref      TEXT        NOT NULL,
    file_path     TEXT        NOT NULL,
    src_blob_sha  TEXT        NOT NULL,
    dst_blob_sha  TEXT        NOT NULL,
    viewed_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT diff_file_viewed_states_pkey
        PRIMARY KEY (tenant_id, user_id, repo_id, base_ref, head_ref, file_path)
);

ALTER TABLE diff_file_viewed_states ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON diff_file_viewed_states;
CREATE POLICY tenant_isolation_policy ON diff_file_viewed_states AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
