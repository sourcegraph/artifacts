CREATE TABLE IF NOT EXISTS notification_email_jobs (
    id                BIGSERIAL PRIMARY KEY,
    notification_id   BIGINT NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    tenant_id         INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    title             TEXT NOT NULL,
    message           TEXT NOT NULL,
    href              TEXT,

    state             TEXT NOT NULL DEFAULT 'queued',
    queued_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at        TIMESTAMP WITH TIME ZONE,
    finished_at       TIMESTAMP WITH TIME ZONE,
    process_after     TIMESTAMP WITH TIME ZONE,
    num_resets        INTEGER NOT NULL DEFAULT 0,
    num_failures      INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    execution_logs    JSON[],
    worker_hostname   TEXT NOT NULL DEFAULT '',
    failure_message   TEXT,
    cancel            BOOLEAN NOT NULL DEFAULT FALSE
);

ALTER TABLE notification_email_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON notification_email_jobs;
CREATE POLICY tenant_isolation_policy ON notification_email_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant'::text) = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant)
    );

CREATE INDEX IF NOT EXISTS notification_email_jobs_dequeue_idx
    ON notification_email_jobs (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

CREATE INDEX IF NOT EXISTS notification_email_jobs_notification_id_idx
    ON notification_email_jobs (notification_id, tenant_id);
