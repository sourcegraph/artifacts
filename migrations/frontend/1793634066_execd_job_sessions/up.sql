CREATE TABLE IF NOT EXISTS execd_job_sessions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    job_id BIGINT NOT NULL,
    queue TEXT NOT NULL,
    session_id BIGINT NOT NULL REFERENCES execd_sessions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, session_id)
);

CREATE INDEX IF NOT EXISTS execd_job_sessions_job ON execd_job_sessions (tenant_id, queue, job_id);

ALTER TABLE execd_job_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON execd_job_sessions;
CREATE POLICY tenant_isolation_policy ON execd_job_sessions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
