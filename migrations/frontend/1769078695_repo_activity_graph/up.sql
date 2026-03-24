-- Table to track when each repo was last processed for activity graph
CREATE TABLE IF NOT EXISTS repo_activity_graph_states (
    repo_id                   INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    last_processed_at         TIMESTAMP WITH TIME ZONE,
    last_processed_commit_sha TEXT,
    repo_birth_date           DATE,
    tenant_id                 INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (repo_id, tenant_id)
);

ALTER TABLE repo_activity_graph_states ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON repo_activity_graph_states;
CREATE POLICY tenant_isolation_policy ON repo_activity_graph_states AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS repo_activity_graph_states_tenant_repo_idx
    ON repo_activity_graph_states (tenant_id, repo_id);

-- dbworker queue table for processing activity graph jobs
CREATE TABLE IF NOT EXISTS repo_activity_graph_jobs (
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

ALTER TABLE repo_activity_graph_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON repo_activity_graph_jobs;
CREATE POLICY tenant_isolation_policy ON repo_activity_graph_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant)));

-- Allow only one concurrent job per repo
CREATE UNIQUE INDEX IF NOT EXISTS repo_activity_graph_jobs_one_per_repo
    ON repo_activity_graph_jobs (repo_id, tenant_id)
    WHERE state IN ('queued', 'processing', 'errored');

-- Dequeue indexes
CREATE INDEX IF NOT EXISTS repo_activity_graph_jobs_dequeue_idx
    ON repo_activity_graph_jobs (state, process_after);

CREATE INDEX IF NOT EXISTS repo_activity_graph_jobs_dequeue_order_idx
    ON repo_activity_graph_jobs (COALESCE(process_after, queued_at) ASC, id ASC, tenant_id);

-- Reverse lookup for FK cascade
CREATE INDEX IF NOT EXISTS repo_activity_graph_jobs_repo_idx
    ON repo_activity_graph_jobs (repo_id, tenant_id);

-- Multi-resolution activity points table
-- granularity: 1=DAY, 2=WEEK, 3=MONTH
CREATE TABLE IF NOT EXISTS repo_activity_graph_points (
    repo_id      INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    bucket_start DATE NOT NULL,
    granularity  SMALLINT NOT NULL,
    commit_count INTEGER NOT NULL DEFAULT 0,
    tenant_id    INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (repo_id, granularity, bucket_start, tenant_id)
);

ALTER TABLE repo_activity_graph_points ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON repo_activity_graph_points;
CREATE POLICY tenant_isolation_policy ON repo_activity_graph_points AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

-- Index for fast range queries
CREATE INDEX IF NOT EXISTS repo_activity_graph_points_query_idx
    ON repo_activity_graph_points (tenant_id, repo_id, granularity, bucket_start DESC);
