-- Undo the changes: drop the new tables and recreate the old ones

DROP TABLE IF EXISTS abc_node_states;
DROP TABLE IF EXISTS abc_executor_tasks;
DROP TABLE IF EXISTS abc_workflow_instances;

-- Recreate the old abc_workflow_executions table
CREATE TABLE IF NOT EXISTS abc_workflow_executions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    workflow_id BIGINT NOT NULL REFERENCES abc_workflows(id) ON DELETE CASCADE,
    definition TEXT NOT NULL,
    variables JSONB NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'queued',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT abc_workflow_executions_status_check CHECK (status IN ('queued', 'running', 'complete', 'failed'))
);

ALTER TABLE abc_workflow_executions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON abc_workflow_executions;
CREATE POLICY tenant_isolation_policy ON abc_workflow_executions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS abc_workflow_executions_tenant_id_idx ON abc_workflow_executions (tenant_id);
CREATE INDEX IF NOT EXISTS abc_workflow_executions_workflow_id_idx ON abc_workflow_executions (tenant_id, workflow_id);
CREATE INDEX IF NOT EXISTS abc_workflow_executions_status_idx ON abc_workflow_executions (tenant_id, status) WHERE status IN ('queued', 'running');
CREATE INDEX IF NOT EXISTS abc_workflow_executions_created_at_idx ON abc_workflow_executions (tenant_id, workflow_id, created_at DESC);

-- Recreate abc_executor_tasks with old foreign key
CREATE TABLE IF NOT EXISTS abc_executor_tasks (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,

    -- Task specification
    image TEXT NOT NULL,
    command TEXT[] NOT NULL DEFAULT '{}',
    env JSONB NOT NULL DEFAULT '{}',
    timeout_seconds INTEGER,

    -- Execution state (managed by executor/dbworker infrastructure)
    state TEXT NOT NULL DEFAULT 'queued',
    failure_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    process_after TIMESTAMP WITH TIME ZONE,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    worker_hostname TEXT NOT NULL DEFAULT '',
    cancel BOOLEAN NOT NULL DEFAULT FALSE,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    execution_logs JSON,

    -- Results
    exit_code INTEGER,
    stdout TEXT,
    stderr TEXT,

    -- Relationship to workflow execution
    execution_id BIGINT NOT NULL REFERENCES abc_workflow_executions(id) ON DELETE CASCADE,
    node_id TEXT NOT NULL,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    queued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT abc_executor_tasks_state_check CHECK (state IN ('queued', 'processing', 'errored', 'failed', 'completed', 'canceled'))
);

ALTER TABLE abc_executor_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON abc_executor_tasks;
CREATE POLICY tenant_isolation_policy ON abc_executor_tasks AS PERMISSIVE FOR ALL TO PUBLIC
    USING (( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant)));

CREATE INDEX IF NOT EXISTS abc_executor_tasks_dequeue_idx ON abc_executor_tasks (tenant_id, state, process_after) WHERE state = 'queued';
CREATE INDEX IF NOT EXISTS abc_executor_tasks_execution_idx ON abc_executor_tasks (tenant_id, execution_id);
CREATE INDEX IF NOT EXISTS abc_executor_tasks_state_idx ON abc_executor_tasks (tenant_id, state) WHERE state IN ('queued', 'processing');

-- Recreate abc_node_states with old column name
CREATE TABLE IF NOT EXISTS abc_node_states (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    instance_id BIGINT NOT NULL REFERENCES abc_workflow_executions(id) ON DELETE CASCADE,
    node_spec_id TEXT NOT NULL,
    status TEXT NOT NULL,
    output TEXT NOT NULL DEFAULT '',
    node_type TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT abc_node_states_status_check CHECK (status IN ('queued', 'running', 'complete', 'failed'))
);

ALTER TABLE abc_node_states ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON abc_node_states;
CREATE POLICY tenant_isolation_policy ON abc_node_states AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS abc_node_states_tenant_idx ON abc_node_states (tenant_id);
CREATE INDEX IF NOT EXISTS abc_node_states_instance_idx ON abc_node_states (tenant_id, instance_id);
CREATE INDEX IF NOT EXISTS abc_node_states_latest_idx ON abc_node_states (tenant_id, instance_id, created_at DESC);
