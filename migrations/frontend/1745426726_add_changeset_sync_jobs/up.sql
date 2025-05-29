CREATE TABLE IF NOT EXISTS changeset_sync_jobs (
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

  -- Changeset sync job fields:
  changeset_id       integer not null REFERENCES changesets(id) ON DELETE CASCADE DEFERRABLE,
  priority           integer not null DEFAULT 100,
  tenant_id          integer not null DEFAULT (current_setting('app.current_tenant'::text))::integer REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE
);

-- Enable RLS
ALTER TABLE changeset_sync_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON changeset_sync_jobs;
CREATE POLICY tenant_isolation_policy ON changeset_sync_jobs AS PERMISSIVE FOR ALL TO PUBLIC USING (( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant)));

-- Allow only one job per changeset
CREATE UNIQUE INDEX IF NOT EXISTS changeset_sync_jobs_one_concurrent_per_changeset
  ON changeset_sync_jobs (changeset_id, tenant_id)
  WHERE (state IN('queued', 'processing', 'errored'));

-- Indexes for efficient queue processing
CREATE INDEX IF NOT EXISTS changeset_sync_jobs_dequeue_idx
  ON changeset_sync_jobs (state, process_after);

CREATE INDEX IF NOT EXISTS changeset_sync_jobs_dequeue_order_idx
  ON changeset_sync_jobs (priority DESC, coalesce(process_after, queued_at) ASC, id ASC, tenant_id);

-- Reverse lookup index to make deleting changesets efficient with the FK.
CREATE INDEX IF NOT EXISTS idx_changeset_sync_jobs_changeset_id ON changeset_sync_jobs (changeset_id, tenant_id);
