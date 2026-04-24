-- Create v2 activity graph tables so workers can rebuild data from scratch
-- without touching legacy tables.
CREATE TABLE IF NOT EXISTS repo_activity_graph_states_v2 (
    repo_id                   INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    last_processed_at         TIMESTAMP WITH TIME ZONE,
    last_processed_commit_sha TEXT,
    repo_birth_date           DATE,
    tenant_id                 INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (repo_id, tenant_id)
);

ALTER TABLE repo_activity_graph_states_v2 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON repo_activity_graph_states_v2;
CREATE POLICY tenant_isolation_policy ON repo_activity_graph_states_v2 AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE TABLE IF NOT EXISTS repo_activity_graph_jobs_v2 (
    id                BIGSERIAL PRIMARY KEY,
    state             TEXT NOT NULL DEFAULT 'queued',
    failure_message   TEXT,
    queued_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    started_at        TIMESTAMP WITH TIME ZONE,
    finished_at       TIMESTAMP WITH TIME ZONE,
    process_after     TIMESTAMP WITH TIME ZONE,
    num_resets        INTEGER NOT NULL DEFAULT 0,
    num_failures      INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    execution_logs    JSON[],
    worker_hostname   TEXT NOT NULL DEFAULT '',
    cancel            BOOLEAN NOT NULL DEFAULT false,
    repo_id           INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    from_commit       TEXT,
    tenant_id         INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

ALTER TABLE repo_activity_graph_jobs_v2 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON repo_activity_graph_jobs_v2;
CREATE POLICY tenant_isolation_policy ON repo_activity_graph_jobs_v2 AS PERMISSIVE FOR ALL TO PUBLIC
    USING (( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant)));

CREATE UNIQUE INDEX IF NOT EXISTS repo_activity_graph_jobs_v2_one_per_repo
    ON repo_activity_graph_jobs_v2 (repo_id, tenant_id)
    WHERE state IN ('queued', 'processing', 'errored');

CREATE INDEX IF NOT EXISTS repo_activity_graph_jobs_v2_dequeue_idx
    ON repo_activity_graph_jobs_v2 (state, process_after);

CREATE INDEX IF NOT EXISTS repo_activity_graph_jobs_v2_dequeue_order_idx
    ON repo_activity_graph_jobs_v2 (COALESCE(process_after, queued_at) ASC, id ASC, tenant_id);

CREATE INDEX IF NOT EXISTS repo_activity_graph_jobs_v2_repo_idx
    ON repo_activity_graph_jobs_v2 (repo_id, tenant_id);

CREATE TABLE IF NOT EXISTS repo_activity_graph_points_v2 (
    repo_id      INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    bucket_start DATE NOT NULL,
    granularity  SMALLINT NOT NULL,
    commit_count INTEGER NOT NULL DEFAULT 0,
    tenant_id    INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (repo_id, granularity, bucket_start, tenant_id)
);

ALTER TABLE repo_activity_graph_points_v2 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON repo_activity_graph_points_v2;
CREATE POLICY tenant_isolation_policy ON repo_activity_graph_points_v2 AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
