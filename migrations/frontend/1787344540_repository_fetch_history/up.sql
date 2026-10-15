ALTER TABLE repo_update_jobs
    ADD COLUMN IF NOT EXISTS reason text NOT NULL DEFAULT 'UNKNOWN';

CREATE TABLE IF NOT EXISTS repository_fetch_history (
    id bigserial PRIMARY KEY,
    repository_id integer NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    repo_update_job_id bigint,
    reason text NOT NULL,
    operation text NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone NOT NULL,
    success boolean NOT NULL,
    failure_message text,
    refs_changed boolean,
    default_branch_tip text,
    commit_discovery_duration_ms bigint,
    commit_discovery_rejection_reason text,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer
        REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,
    CONSTRAINT repository_fetch_history_valid_times CHECK (finished_at >= started_at),
    CONSTRAINT repository_fetch_history_valid_failure_message CHECK ((success AND failure_message IS NULL) OR (NOT success AND failure_message IS NOT NULL)),
    CONSTRAINT repository_fetch_history_valid_discovery_duration CHECK (commit_discovery_duration_ms IS NULL OR commit_discovery_duration_ms >= 0),
    CONSTRAINT repository_fetch_history_one_discovery_result CHECK ((commit_discovery_duration_ms IS NULL) <> (commit_discovery_rejection_reason IS NULL))
);

ALTER TABLE repository_fetch_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON repository_fetch_history;
CREATE POLICY tenant_isolation_policy ON repository_fetch_history AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS repository_fetch_history_started_at
    ON repository_fetch_history (tenant_id, started_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS repository_fetch_history_repository_id
    ON repository_fetch_history (tenant_id, repository_id, started_at DESC, id DESC);
CREATE UNIQUE INDEX IF NOT EXISTS repository_fetch_history_repo_update_job_id
    ON repository_fetch_history (tenant_id, repo_update_job_id) WHERE repo_update_job_id IS NOT NULL;
