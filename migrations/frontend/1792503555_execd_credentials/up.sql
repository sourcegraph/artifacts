-- The credentials of the enrolled execd deployment. There is at most one row
-- per tenant.
CREATE TABLE IF NOT EXISTS execd_credentials (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    sourcegraph_credential TEXT NOT NULL,
    sourcegraph_credential_encryption_key_id TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_enrolled_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    -- The ID of the enrollment public key that the last enrollment used.
    last_enrolled_key_id TEXT NOT NULL,
    CONSTRAINT execd_credentials_tenant_id_unique UNIQUE (tenant_id)
);

ALTER TABLE execd_credentials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON execd_credentials;
CREATE POLICY tenant_isolation_policy ON execd_credentials AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
