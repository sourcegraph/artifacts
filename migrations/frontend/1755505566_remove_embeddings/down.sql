-- Drop view before adding back column
DROP VIEW IF EXISTS codeintel_configuration_policies;

-- Restore column removed from lsif_configuration_policies
ALTER TABLE lsif_configuration_policies
    ADD COLUMN IF NOT EXISTS embeddings_enabled boolean DEFAULT false NOT NULL;

-- Recreate view with embeddings_enabled column
CREATE VIEW codeintel_configuration_policies WITH (security_invoker = TRUE) AS
SELECT id,
       repository_id,
       name,
       type,
       pattern,
       retention_enabled,
       retention_duration_hours,
       retain_intermediate_commits,
       indexing_enabled,
       index_commit_max_age_hours,
       index_intermediate_commits,
       protected,
       repository_patterns,
       last_resolved_at,
       embeddings_enabled
FROM lsif_configuration_policies;

-- Restore tables removed by the up migration
CREATE TABLE IF NOT EXISTS context_detection_embedding_jobs (
    id serial PRIMARY KEY,
    state text DEFAULT 'queued'::text,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

DROP POLICY IF EXISTS tenant_isolation_policy ON context_detection_embedding_jobs;
CREATE POLICY tenant_isolation_policy ON context_detection_embedding_jobs 
    USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));
ALTER TABLE context_detection_embedding_jobs ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS repo_embedding_jobs (
    id serial PRIMARY KEY,
    state text DEFAULT 'queued'::text,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    repo_id integer NOT NULL,
    revision text NOT NULL,
    commit_id text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE INDEX IF NOT EXISTS repo_embedding_jobs_repo ON repo_embedding_jobs USING btree (repo_id, revision);

DROP POLICY IF EXISTS tenant_isolation_policy ON repo_embedding_jobs;
CREATE POLICY tenant_isolation_policy ON repo_embedding_jobs 
    USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));
ALTER TABLE repo_embedding_jobs ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS repo_embedding_job_stats (
    job_id integer PRIMARY KEY REFERENCES repo_embedding_jobs(id) ON DELETE CASCADE DEFERRABLE,
    is_incremental boolean DEFAULT false NOT NULL,
    files_total integer DEFAULT 0 NOT NULL,
    files_embedded integer DEFAULT 0 NOT NULL,
    chunks_embedded integer DEFAULT 0 NOT NULL,
    files_excluded integer DEFAULT 0 NOT NULL,
    files_skipped jsonb DEFAULT '{}'::jsonb NOT NULL,
    bytes_embedded bigint DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

DROP POLICY IF EXISTS tenant_isolation_policy ON repo_embedding_job_stats;
CREATE POLICY tenant_isolation_policy ON repo_embedding_job_stats
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));
ALTER TABLE repo_embedding_job_stats ENABLE ROW LEVEL SECURITY;
