ALTER TABLE zoekt_repos ADD COLUMN IF NOT EXISTS last_index_attempt_at timestamp with time zone;
ALTER TABLE zoekt_repos ADD COLUMN IF NOT EXISTS failed_index_attempts integer not null DEFAULT 0;

CREATE TABLE IF NOT EXISTS zoekt_index_jobs (
  id BIGSERIAL PRIMARY KEY,

  -- Worker fields:
  state             text not null DEFAULT 'queued',
  failure_message   text,
  queued_at         timestamp with time zone not null DEFAULT NOW(),
  started_at        timestamp with time zone,
  finished_at       timestamp with time zone,
  process_after     timestamp with time zone,
  num_resets        integer not null default 0,
  num_failures      integer not null default 0,
  last_heartbeat_at timestamp with time zone,
  execution_logs    json[],
  worker_hostname   text not null default '',
  cancel            boolean not null default false,

  -- Zoekt index job fields:
  repository_id     integer not null REFERENCES repo(id) ON DELETE CASCADE,
  priority          integer not null DEFAULT 1,
  tenant_id         integer not null DEFAULT (current_setting('app.current_tenant'::text))::integer
);

ALTER TABLE zoekt_index_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON zoekt_index_jobs;
CREATE POLICY tenant_isolation_policy ON zoekt_index_jobs AS PERMISSIVE FOR ALL TO PUBLIC USING (( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant)));

-- Ensure only one pending/running zoekt index job per repo at a time.
CREATE UNIQUE INDEX IF NOT EXISTS zoekt_index_jobs_one_concurrent_per_repo ON zoekt_index_jobs (repository_id, tenant_id) WHERE (state IN('queued', 'processing', 'errored'));

-- Ensure dequeues are fast.
CREATE INDEX IF NOT EXISTS zoekt_index_jobs_dequeue_idx ON zoekt_index_jobs (state, process_after);
CREATE INDEX IF NOT EXISTS zoekt_index_jobs_dequeue_order_idx ON zoekt_index_jobs (priority DESC, coalesce(process_after, queued_at) ASC, id ASC, tenant_id);

-- Speed up lookups by repo ID and foreign key cascades on repository_id.
CREATE INDEX IF NOT EXISTS
    idx_zoekt_index_jobs_repository_id
ON zoekt_index_jobs (tenant_id, repository_id);
