CREATE TABLE IF NOT EXISTS lsif_index_execution_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    index_id BIGINT NOT NULL REFERENCES lsif_indexes(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    command TEXT[] NOT NULL DEFAULT '{}'::text[],
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_code INTEGER,
    out TEXT NOT NULL DEFAULT '',
    duration_ms INTEGER,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE lsif_index_execution_logs IS 'Executor log entries for auto-indexing jobs (lsif_indexes), one row per executed step. Rows are written by the executor queue while the job runs and deleted when the job is dequeued again. Entries recorded before this table existed remain in lsif_indexes.execution_logs.';
COMMENT ON COLUMN lsif_index_execution_logs.key IS 'The executor step key, such as setup.git.init or step.docker.indexer.';
COMMENT ON COLUMN lsif_index_execution_logs.out IS 'The combined stdout and stderr of the step. Replaced wholesale on every update while the step is running.';

CREATE INDEX IF NOT EXISTS lsif_index_execution_logs_index_id ON lsif_index_execution_logs(tenant_id, index_id);

ALTER TABLE lsif_index_execution_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON lsif_index_execution_logs;
CREATE POLICY tenant_isolation_policy ON lsif_index_execution_logs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));
