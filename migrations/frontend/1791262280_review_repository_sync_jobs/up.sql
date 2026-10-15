CREATE TABLE IF NOT EXISTS review_repository_sync_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    github_app_id INTEGER NOT NULL REFERENCES github_apps(id) ON DELETE CASCADE,
    github_installation_id BIGINT NOT NULL,
    external_repository_id BIGINT NOT NULL,
    repository_name TEXT NOT NULL,
    pull_request_number BIGINT NOT NULL,

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
    cancel BOOLEAN NOT NULL DEFAULT FALSE
);

-- A signal received during processing creates a follow-up job. Excluding reset
-- jobs lets the dbworker resetter requeue a stalled job alongside that follow-up.
CREATE UNIQUE INDEX IF NOT EXISTS review_repository_sync_jobs_pending_idx
    ON review_repository_sync_jobs (tenant_id, github_app_id, external_repository_id, pull_request_number)
    WHERE state = 'queued' AND num_resets = 0;
CREATE INDEX IF NOT EXISTS review_repository_sync_jobs_dequeue_idx
    ON review_repository_sync_jobs (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');
CREATE INDEX IF NOT EXISTS review_repository_sync_jobs_history_idx
    ON review_repository_sync_jobs (tenant_id, github_app_id, external_repository_id, pull_request_number, started_at DESC);

ALTER TABLE review_repository_sync_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON review_repository_sync_jobs;
CREATE POLICY tenant_isolation_policy ON review_repository_sync_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );

CREATE TABLE IF NOT EXISTS change_requests (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    external_service_type TEXT NOT NULL,
    code_host_url TEXT NOT NULL,
    external_repository_id TEXT NOT NULL,
    repository_name TEXT NOT NULL,
    code_host_id TEXT NOT NULL,
    number BIGINT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    external_url TEXT NOT NULL,
    state TEXT NOT NULL,
    draft BOOLEAN NOT NULL,
    author TEXT NOT NULL,
    assignees TEXT[] NOT NULL DEFAULT '{}',
    requested_reviewers TEXT[] NOT NULL DEFAULT '{}',
    requested_teams TEXT[] NOT NULL DEFAULT '{}',
    labels TEXT[] NOT NULL DEFAULT '{}',
    head_ref TEXT NOT NULL,
    head_sha TEXT NOT NULL,
    base_ref TEXT NOT NULL,
    base_sha TEXT NOT NULL,
    external_created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    external_updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE,
    merged_at TIMESTAMP WITH TIME ZONE,
    synced_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    external_data JSONB NOT NULL,
    CONSTRAINT change_requests_key UNIQUE (tenant_id, external_service_type, code_host_url, external_repository_id, number)
);

CREATE INDEX IF NOT EXISTS change_requests_state_created_at_idx
    ON change_requests (tenant_id, state, external_created_at, id);
CREATE INDEX IF NOT EXISTS change_requests_requested_reviewers_idx
    ON change_requests USING GIN (requested_reviewers);
CREATE INDEX IF NOT EXISTS change_requests_requested_teams_idx
    ON change_requests USING GIN (requested_teams);
CREATE INDEX IF NOT EXISTS change_requests_head_sha_idx
    ON change_requests (tenant_id, external_service_type, code_host_url, external_repository_id, head_sha);

ALTER TABLE change_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_requests;
CREATE POLICY tenant_isolation_policy ON change_requests AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
