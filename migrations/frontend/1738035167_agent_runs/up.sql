CREATE TABLE IF NOT EXISTS agent_runs (
    id                 SERIAL PRIMARY KEY,
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    tenant_id          INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    agent_id           INTEGER REFERENCES agents(id) ON DELETE CASCADE,
    status             TEXT NOT NULL,
    program_id         INTEGER REFERENCES agent_programs(id) ON DELETE SET NULL,
    parameters         JSONB,
    results            JSONB NOT NULL DEFAULT '[]',
    CONSTRAINT agent_runs_status_check CHECK (status IN ('pending', 'running', 'completed', 'failed'))
);

COMMENT ON COLUMN agent_runs.agent_id IS E''
   'intentionally not null because it allows us to create a run early '
   'in a webhook handler before we have identified an associated agent';

ALTER TABLE agent_runs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_runs;
CREATE POLICY tenant_isolation_policy ON agent_runs AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE INDEX IF NOT EXISTS agent_runs_agent_id_idx ON agent_runs (agent_id);
CREATE INDEX IF NOT EXISTS agent_runs_updated_at_idx ON agent_runs (updated_at);

CREATE UNLOGGED TABLE IF NOT EXISTS agent_run_logs (
    id         BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    tenant_id  INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    run_id     INTEGER NOT NULL REFERENCES agent_runs(id) ON DELETE CASCADE,
    severity   TEXT NOT NULL,
    message    TEXT NOT NULL,
    fields     JSONB,

    CONSTRAINT agent_run_logs_severity_check CHECK (severity IN ('debug', 'info', 'warning', 'error'))
);

COMMENT ON COLUMN agent_run_logs.id IS 'intentionally bigserial because just a single run can have a lot of logs';

COMMENT ON TABLE agent_run_logs IS E''
  'unlogged table to support write-heavy workloads. '
  'The logs are not critical data so we''re willing to accept the tradeoff that '
  'this data may get lost if the database crashes.';

ALTER TABLE agent_run_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_run_logs;
CREATE POLICY tenant_isolation_policy ON agent_run_logs AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE INDEX IF NOT EXISTS agent_run_logs_run_id_idx ON agent_run_logs (run_id);


CREATE OR REPLACE FUNCTION update_agent_runs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_agent_runs_updated_at
    BEFORE UPDATE ON agent_runs
    FOR EACH ROW
    EXECUTE FUNCTION update_agent_runs_updated_at();
