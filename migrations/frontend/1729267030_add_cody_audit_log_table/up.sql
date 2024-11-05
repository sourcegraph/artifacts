CREATE UNLOGGED TABLE IF NOT EXISTS cody_audit_log (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    protobuf_payload bytea,
    codebase_name TEXT,
    file_name TEXT
);

CREATE INDEX IF NOT EXISTS idx_user_id_created_at ON cody_audit_log(user_id, created_at);

COMMENT ON COLUMN cody_audit_log.user_id IS 'Identifies the user who originally created this record. This is not a foreign key reference to users(id) to ensure records persist beyond the lifetime of a user account. Do not assume this can be used for JOINs with the users table.';

ALTER TABLE cody_audit_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS cody_audit_log_isolation_policy ON cody_audit_log;
CREATE POLICY cody_audit_log_isolation_policy ON cody_audit_log AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = current_setting('app.current_tenant')::integer);
