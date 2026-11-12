-- Executors v3 sessions as seen by the Sourcegraph backend. The session
-- manager owns the sandbox; the backend records which sessions it requested
-- and what it last observed about them.
CREATE TABLE IF NOT EXISTS executor_sessions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    request_id TEXT NOT NULL,
    manager_session_id TEXT,
    state TEXT NOT NULL DEFAULT 'creating',
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_transitioned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT executor_sessions_request_id_key UNIQUE (tenant_id, request_id)
);

ALTER TABLE executor_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON executor_sessions;
CREATE POLICY tenant_isolation_policy ON executor_sessions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE UNIQUE INDEX IF NOT EXISTS executor_sessions_manager_session_id_key
    ON executor_sessions (tenant_id, manager_session_id)
    WHERE manager_session_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS executor_sessions_state_idx
    ON executor_sessions (state, id);

CREATE INDEX IF NOT EXISTS executor_sessions_prunable_idx
    ON executor_sessions (last_transitioned_at)
    WHERE state IN ('failed', 'deleted');

COMMENT ON COLUMN executor_sessions.request_id IS 'Backend-generated idempotency key sent to the session manager when creating the session.';
COMMENT ON COLUMN executor_sessions.manager_session_id IS 'Session identifier assigned by the session manager.';

-- Each execution is one attempt of a command within a session. Its id is the
-- exec_id that the backend sends to the executor. Retries of a command share
-- its command_key and have increasing attempt numbers.
CREATE TABLE IF NOT EXISTS executor_session_executions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    session_id BIGINT NOT NULL REFERENCES executor_sessions(id) ON DELETE CASCADE,
    command_key TEXT NOT NULL,
    attempt INTEGER NOT NULL,
    command TEXT NOT NULL,
    args TEXT[] NOT NULL DEFAULT '{}',
    spec JSONB NOT NULL DEFAULT '{}'::jsonb,
    state TEXT NOT NULL DEFAULT 'requested',
    process_id INTEGER,
    exit_code INTEGER,
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_transitioned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT executor_session_executions_session_id_id_key UNIQUE (session_id, id),
    CONSTRAINT executor_session_executions_attempt_key UNIQUE (session_id, command_key, attempt)
);

ALTER TABLE executor_session_executions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON executor_session_executions;
CREATE POLICY tenant_isolation_policy ON executor_session_executions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

COMMENT ON COLUMN executor_session_executions.command_key IS 'Caller-chosen identity of the command within its session, such as a step name. Executions with the same key are attempts of the same command.';
COMMENT ON COLUMN executor_session_executions.command IS 'Program to run, resolved by the executor rather than a shell.';
COMMENT ON COLUMN executor_session_executions.spec IS 'Remaining process spec, such as working directory, image, and environment references. Never contains secret values.';
COMMENT ON COLUMN executor_session_executions.process_id IS 'Process ID reported by the executor once the execution started.';

-- Append-only journal of every state transition and action taken for a
-- session, used to reconstruct how a session reached its state.
CREATE TABLE IF NOT EXISTS executor_session_events (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    session_id BIGINT NOT NULL REFERENCES executor_sessions(id) ON DELETE CASCADE,
    execution_id BIGINT,
    kind TEXT NOT NULL,
    from_state TEXT,
    to_state TEXT,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    FOREIGN KEY (session_id, execution_id) REFERENCES executor_session_executions (session_id, id) ON DELETE CASCADE
);

ALTER TABLE executor_session_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON executor_session_events;
CREATE POLICY tenant_isolation_policy ON executor_session_events AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS executor_session_events_session_id_idx
    ON executor_session_events (session_id, id);

CREATE INDEX IF NOT EXISTS executor_session_events_execution_id_idx
    ON executor_session_events (execution_id)
    WHERE execution_id IS NOT NULL;
