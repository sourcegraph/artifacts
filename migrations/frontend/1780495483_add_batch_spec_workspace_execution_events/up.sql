CREATE TABLE IF NOT EXISTS batch_spec_workspace_execution_events (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    job_id BIGINT NOT NULL REFERENCES batch_spec_workspace_execution_jobs(id) ON DELETE CASCADE,
    step INTEGER,
    operation TEXT NOT NULL,
    status TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE batch_spec_workspace_execution_events IS 'Stores semantic batcheslib.LogEvent rows emitted by an execution. One shape houses both v1 and v2 executions; the execution version is intentionally not a column.';
COMMENT ON COLUMN batch_spec_workspace_execution_events.step IS 'Step index this event refers to, extracted from the event metadata where present. NULL for non-step operations.';
COMMENT ON COLUMN batch_spec_workspace_execution_events.metadata IS 'The batcheslib.LogEvent metadata payload, operation-specific.';

CREATE INDEX IF NOT EXISTS batch_spec_workspace_execution_events_job_id_step_idx ON batch_spec_workspace_execution_events(tenant_id, job_id, step);

ALTER TABLE batch_spec_workspace_execution_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_spec_workspace_execution_events;
CREATE POLICY tenant_isolation_policy ON batch_spec_workspace_execution_events AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));
