-- The Slack account that each user linked to receive review notifications.
-- Users link an account by opening a link that the Slack app sent to it.
CREATE TABLE IF NOT EXISTS change_request_slack_accounts (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    slack_configuration_id INTEGER NOT NULL REFERENCES slack_configurations(id) ON DELETE CASCADE,
    slack_user_id TEXT NOT NULL,
    -- The Slack user's and workspace's names when the account was linked, for display only.
    slack_user_name TEXT NOT NULL,
    slack_workspace_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT change_request_slack_accounts_user_key UNIQUE (tenant_id, user_id),
    CONSTRAINT change_request_slack_accounts_slack_user_key UNIQUE (tenant_id, slack_configuration_id, slack_user_id)
);

ALTER TABLE change_request_slack_accounts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_slack_accounts;
CREATE POLICY tenant_isolation_policy ON change_request_slack_accounts AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

-- Notifies one requested reviewer, or fans out to the members of one
-- requested team, about a review request of a change request.
CREATE TABLE IF NOT EXISTS change_request_review_notification_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    -- The code-host account ID of the requested reviewer.
    reviewer_external_id TEXT,
    team_id BIGINT REFERENCES change_request_teams(id) ON DELETE CASCADE,

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
    CONSTRAINT change_request_review_notification_jobs_reviewer_check CHECK ((reviewer_external_id IS NULL) <> (team_id IS NULL))
);

ALTER TABLE change_request_review_notification_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_review_notification_jobs;
CREATE POLICY tenant_isolation_policy ON change_request_review_notification_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant)
    );

CREATE INDEX IF NOT EXISTS change_request_review_notification_jobs_dequeue_idx
    ON change_request_review_notification_jobs (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

CREATE INDEX IF NOT EXISTS change_request_review_notification_jobs_change_request_idx
    ON change_request_review_notification_jobs (change_request_id, queued_at);
