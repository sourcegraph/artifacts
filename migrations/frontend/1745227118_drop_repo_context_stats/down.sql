CREATE TABLE IF NOT EXISTS repo_context_stats_jobs (
    tenant_id integer NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,

    id SERIAL PRIMARY KEY,
    state text DEFAULT 'queued',
    failure_message text,
    queued_at timestamp with time zone DEFAULT NOW(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer not null default 0,
    num_failures integer not null default 0,
    last_heartbeat_at timestamp with time zone,
    execution_logs json [],
    worker_hostname text not null default '',
    cancel            boolean not null default false,

    repo_id integer not null REFERENCES repo (id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,
    revision text not null
);
CREATE INDEX IF NOT EXISTS repo_context_stats_jobs_repo_id ON repo_context_stats_jobs (repo_id);

CREATE TABLE IF NOT EXISTS repo_context_stats (
    tenant_id integer NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,

    id SERIAL PRIMARY KEY,
    repo_id integer not null REFERENCES repo (id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE,
    revision text not null,
    stats_bytes bytea not null,
    stats_bytes_schema_version integer not null default 1,

    UNIQUE(repo_id)
);

ALTER TABLE IF EXISTS repo_context_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS repo_context_stats_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON repo_context_stats;
CREATE POLICY tenant_isolation_policy ON repo_context_stats USING ((tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

DROP POLICY IF EXISTS tenant_isolation_policy ON repo_context_stats_jobs;
CREATE POLICY tenant_isolation_policy ON repo_context_stats_jobs USING (((SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = (SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

