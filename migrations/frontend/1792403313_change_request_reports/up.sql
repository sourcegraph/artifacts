-- Each row is both a review report and its generation job.
CREATE TABLE IF NOT EXISTS change_request_reports (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    prompt TEXT NOT NULL,
    effort TEXT NOT NULL,
    -- The change request's revisions when the report was requested.
    base_oid TEXT NOT NULL,
    head_oid TEXT NOT NULL,
    -- The merge base that document line ranges on the base side refer to.
    diff_base_oid TEXT,
    document JSONB,
    partial BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    state TEXT NOT NULL DEFAULT 'queued',
    queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    process_after TIMESTAMPTZ,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMPTZ,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    failure_message TEXT,
    cancel BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS change_request_reports_dequeue_idx
    ON change_request_reports (state, process_after, queued_at, id, tenant_id)
    WHERE state IN ('queued', 'errored');
CREATE INDEX IF NOT EXISTS change_request_reports_creator_idx
    ON change_request_reports (tenant_id, change_request_id, user_id, id DESC);

ALTER TABLE change_request_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_reports;
CREATE POLICY tenant_isolation_policy ON change_request_reports AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );
