CREATE TABLE IF NOT EXISTS gitserver_relocator_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    queued_at timestamp with time zone DEFAULT now(),
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    repo_id integer NOT NULL,
    source_hostname text NOT NULL,
    dest_hostname text NOT NULL,
    delete_source boolean DEFAULT false NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE IF NOT EXISTS gitserver_relocator_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gitserver_relocator_jobs_id_seq OWNED BY gitserver_relocator_jobs.id;

ALTER TABLE ONLY gitserver_relocator_jobs ALTER COLUMN id SET DEFAULT nextval('gitserver_relocator_jobs_id_seq'::regclass);

ALTER TABLE ONLY gitserver_relocator_jobs DROP CONSTRAINT IF EXISTS gitserver_relocator_jobs_pkey;
ALTER TABLE ONLY gitserver_relocator_jobs ADD CONSTRAINT gitserver_relocator_jobs_pkey PRIMARY KEY (id);

CREATE INDEX IF NOT EXISTS gitserver_relocator_jobs_state ON gitserver_relocator_jobs USING btree (state);

ALTER TABLE gitserver_relocator_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON gitserver_relocator_jobs;
CREATE POLICY tenant_isolation_policy ON gitserver_relocator_jobs AS PERMISSIVE FOR ALL TO PUBLIC
    USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE OR REPLACE VIEW gitserver_relocator_jobs_with_repo_name WITH (security_invoker='true') AS
 SELECT glj.id,
    glj.state,
    glj.queued_at,
    glj.failure_message,
    glj.started_at,
    glj.finished_at,
    glj.process_after,
    glj.num_resets,
    glj.num_failures,
    glj.last_heartbeat_at,
    glj.execution_logs,
    glj.worker_hostname,
    glj.repo_id,
    glj.source_hostname,
    glj.dest_hostname,
    glj.delete_source,
    r.name AS repo_name,
    glj.tenant_id
   FROM (gitserver_relocator_jobs glj
     JOIN repo r ON ((r.id = glj.repo_id)));
