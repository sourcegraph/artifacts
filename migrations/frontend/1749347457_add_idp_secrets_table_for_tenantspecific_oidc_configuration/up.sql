CREATE TABLE IF NOT EXISTS idp_secrets (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    oidc_global_secret TEXT NOT NULL,
    oidc_jwk_private_key TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure uniqueness per tenant
ALTER TABLE idp_secrets DROP CONSTRAINT IF EXISTS idp_secrets_tenant_unique;
ALTER TABLE idp_secrets ADD CONSTRAINT idp_secrets_tenant_unique UNIQUE (tenant_id);

-- Index for efficient lookups by tenant_id
CREATE INDEX IF NOT EXISTS idp_secrets_tenant_id_idx ON idp_secrets(tenant_id);

-- Enable Row Level Security for tenant isolation
ALTER TABLE idp_secrets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_secrets;
CREATE POLICY tenant_isolation_policy ON idp_secrets AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

-- Comment on the table
COMMENT ON TABLE idp_secrets IS 'Stores tenant-specific OIDC configuration secrets including global secrets and JWK private keys';
