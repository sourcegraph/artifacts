CREATE TABLE IF NOT EXISTS contributor_data
(
    author_email           TEXT                     NOT NULL,
    repo_id                INTEGER                  NOT NULL REFERENCES repo (id) ON DELETE CASCADE,
    author_name            TEXT                     NOT NULL,
    most_recent_commit_sha TEXT                     NOT NULL,
    last_commit_date       TIMESTAMP WITH TIME ZONE NOT NULL,
    number_of_commits      INTEGER                  NOT NULL,
    tenant_id              INTEGER                  NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (tenant_id, author_email, author_name, repo_id)
);
ALTER TABLE contributor_data ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON contributor_data;
CREATE POLICY tenant_isolation_policy ON contributor_data AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

CREATE TABLE IF NOT EXISTS contributor_repos
(
    repo_id                   INTEGER NOT NULL REFERENCES repo (id) ON DELETE CASCADE,
    last_processed_commit_sha TEXT    NOT NULL,
    tenant_id                 INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (tenant_id, repo_id)
);
ALTER TABLE contributor_repos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON contributor_repos;
CREATE POLICY tenant_isolation_policy ON contributor_repos AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

CREATE TABLE IF NOT EXISTS contributor_jobs
(
    id                SERIAL PRIMARY KEY,
    state             text DEFAULT 'queued',
    failure_message   text,
    queued_at         timestamp with time zone DEFAULT NOW(),
    started_at        timestamp with time zone,
    finished_at       timestamp with time zone,
    process_after     timestamp with time zone,
    num_resets        integer not null default 0,
    num_failures      integer not null default 0,
    last_heartbeat_at timestamp with time zone,
    execution_logs    json[],
    worker_hostname   text not null default '',
    cancel            boolean not null default false,

    repo_id           INTEGER                  NOT NULL REFERENCES repo (id) ON DELETE CASCADE,
    repo_name         TEXT                     NOT NULL,
    from_commit       TEXT,
    tenant_id         INTEGER                  NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

ALTER TABLE contributor_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON contributor_jobs;
CREATE POLICY tenant_isolation_policy ON contributor_jobs AS PERMISSIVE FOR ALL TO PUBLIC USING (( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant)));
