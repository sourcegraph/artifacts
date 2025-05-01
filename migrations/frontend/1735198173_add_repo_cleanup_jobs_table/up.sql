ALTER TABLE gitserver_repos ADD COLUMN IF NOT EXISTS last_cleanup_attempt_at timestamp with time zone;
ALTER TABLE gitserver_repos ADD COLUMN IF NOT EXISTS failed_cleanup_attempts integer not null DEFAULT 0;
ALTER TABLE gitserver_repos ADD COLUMN IF NOT EXISTS last_cleaned_at timestamp with time zone;

COMMIT AND CHAIN;

CREATE TABLE IF NOT EXISTS repo_cleanup_jobs (
    id BIGSERIAL NOT NULL PRIMARY KEY,

    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,

    repository_id integer NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    priority integer DEFAULT 1 NOT NULL,

    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_repo_cleanup_jobs_repository_id ON repo_cleanup_jobs USING btree (tenant_id, repository_id);

CREATE INDEX IF NOT EXISTS repo_cleanup_jobs_dequeue_idx ON repo_cleanup_jobs USING btree (state, process_after);

CREATE INDEX IF NOT EXISTS repo_cleanup_jobs_dequeue_optimization_idx ON repo_cleanup_jobs USING btree (priority DESC, COALESCE(process_after, queued_at), id) INCLUDE (state, process_after) WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));

CREATE INDEX IF NOT EXISTS repo_cleanup_jobs_dequeue_order_idx ON repo_cleanup_jobs USING btree (priority DESC, COALESCE(process_after, queued_at), id, tenant_id);

CREATE UNIQUE INDEX IF NOT EXISTS repo_cleanup_jobs_one_concurrent_per_repo ON repo_cleanup_jobs USING btree (repository_id, tenant_id) WHERE (state = ANY (ARRAY['queued'::text, 'processing'::text, 'errored'::text]));

ALTER TABLE repo_cleanup_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON repo_cleanup_jobs;
CREATE POLICY tenant_isolation_policy ON repo_cleanup_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));
