ALTER TABLE gitserver_repos ADD COLUMN IF NOT EXISTS last_fetch_attempt_at timestamp with time zone;

ALTER TABLE gitserver_repos ADD COLUMN IF NOT EXISTS failed_fetch_attempts integer not null DEFAULT 0;

-- Make sure newly inserted repo records don't appear as "fetched/cloned just now".
ALTER TABLE gitserver_repos ALTER COLUMN last_fetched DROP NOT NULL;
ALTER TABLE gitserver_repos ALTER COLUMN last_fetched DROP DEFAULT;
ALTER TABLE gitserver_repos ALTER COLUMN last_changed DROP NOT NULL;
ALTER TABLE gitserver_repos ALTER COLUMN last_changed DROP DEFAULT;

COMMIT AND CHAIN;

CREATE TABLE IF NOT EXISTS repo_update_jobs (
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

  -- Repo update job fields:
  repository_id     integer not null REFERENCES repo(id) ON DELETE CASCADE,
  priority          integer not null DEFAULT 1,
  tenant_id         integer not null DEFAULT (current_setting('app.current_tenant'::text))::integer REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE
);

ALTER TABLE repo_update_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS repo_update_jobs_isolation_policy ON repo_update_jobs;
CREATE POLICY repo_update_jobs_isolation_policy ON repo_update_jobs AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = current_setting('app.current_tenant')::integer);

-- Ensure only one pending/running repo update job per repo at a time.
CREATE UNIQUE INDEX IF NOT EXISTS repo_update_jobs_one_concurrent_per_repo ON repo_update_jobs (repository_id, tenant_id) WHERE (state IN('queued', 'processing', 'errored'));

-- Ensure dequeues are fast.
CREATE INDEX IF NOT EXISTS repo_update_jobs_dequeue_idx ON repo_update_jobs (state, process_after);
CREATE INDEX IF NOT EXISTS repo_update_jobs_dequeue_order_idx ON repo_update_jobs (priority DESC, coalesce(process_after, queued_at) ASC, id ASC, tenant_id);

-- Speed up lookups by repo ID and foreign key cascades on repository_id.
CREATE INDEX IF NOT EXISTS
    idx_repo_update_jobs_repository_id
ON repo_update_jobs (tenant_id, repository_id);

COMMIT AND CHAIN;

-- Speed up Schedule Info queries. See query inline documentation.
CREATE INDEX IF NOT EXISTS gitserver_repos_schedule_order_idx ON gitserver_repos (
    (last_fetch_attempt_at AT TIME ZONE 'UTC' + LEAST(GREATEST(((last_fetched - last_changed) / 2) * (failed_fetch_attempts + 1), interval '45 seconds'), interval '8 hours')) DESC,
    repo_id
);
