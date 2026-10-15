CREATE TABLE IF NOT EXISTS change_request_comment_sync_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    repo_id INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    external_service_type TEXT NOT NULL,
    change_request_external_id TEXT NOT NULL,
    requesting_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    last_synced_at TIMESTAMP WITH TIME ZONE,

    state TEXT NOT NULL DEFAULT 'queued',
    queued_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    process_after TIMESTAMP WITH TIME ZONE,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    failure_message TEXT,
    cancel BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT change_request_comment_sync_jobs_key UNIQUE (
        tenant_id,
        repo_id,
        external_service_type,
        change_request_external_id
    )
);

CREATE INDEX IF NOT EXISTS change_request_comment_sync_jobs_dequeue_idx
    ON change_request_comment_sync_jobs (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

ALTER TABLE change_request_comment_sync_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_comment_sync_jobs;
CREATE POLICY tenant_isolation_policy ON change_request_comment_sync_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );

CREATE TABLE IF NOT EXISTS change_request_comments (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    sync_job_id BIGINT NOT NULL REFERENCES change_request_comment_sync_jobs(id) ON DELETE CASCADE,
    kind TEXT NOT NULL,
    external_id TEXT NOT NULL,
    external_thread_id TEXT,
    body TEXT NOT NULL,
    external_url TEXT NOT NULL,
    author_external_id TEXT,
    author_username TEXT,
    author_avatar_url TEXT,
    external_created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    external_updated_at TIMESTAMP WITH TIME ZONE NOT NULL,

    base_oid TEXT,
    head_oid TEXT,
    src_oid TEXT,
    dst_oid TEXT,
    old_path TEXT,
    new_path TEXT,
    start_line INTEGER,
    start_side TEXT,
    end_line INTEGER,
    end_side TEXT,
    external_data JSONB NOT NULL DEFAULT '{}',
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT change_request_comments_key UNIQUE (tenant_id, sync_job_id, kind, external_id),
    CONSTRAINT change_request_comments_kind_check CHECK (kind IN ('change_request', 'diff')),
    CONSTRAINT change_request_comments_sides_check CHECK (
        (start_side IS NULL OR start_side IN ('base', 'head'))
        AND (end_side IS NULL OR end_side IN ('base', 'head'))
    ),
    CONSTRAINT change_request_comments_lines_check CHECK (
        (start_line IS NULL OR start_line > 0)
        AND (end_line IS NULL OR end_line > 0)
    )
);

CREATE INDEX IF NOT EXISTS change_request_comments_sync_job_id_idx
    ON change_request_comments (tenant_id, sync_job_id, external_created_at, id);

ALTER TABLE change_request_comments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_comments;
CREATE POLICY tenant_isolation_policy ON change_request_comments AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
