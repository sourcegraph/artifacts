CREATE TABLE IF NOT EXISTS batch_spec_library_variables (
    id BIGSERIAL PRIMARY KEY,
    batch_spec_library_record_id BIGINT NOT NULL REFERENCES batch_spec_library_records(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    regex_rule TEXT NOT NULL,
    placeholder TEXT,
    description TEXT,
    level TEXT NOT NULL CHECK (level IN ('error', 'warn', 'info')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

CREATE INDEX IF NOT EXISTS batch_spec_library_variables_library_record_id_idx ON batch_spec_library_variables (batch_spec_library_record_id);

-- Enable RLS
ALTER TABLE batch_spec_library_variables ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_spec_library_variables;
CREATE POLICY tenant_isolation_policy ON batch_spec_library_variables AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
