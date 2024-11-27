DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tenant_state') THEN
        CREATE TYPE tenant_state AS ENUM ('active', 'suspended', 'dormant', 'deleted');
    END IF;
END
$$;

ALTER TABLE tenants ADD COLUMN IF NOT EXISTS state tenant_state NOT NULL DEFAULT 'active';

COMMENT ON COLUMN tenants.state IS 'The state of the tenant. Can be active, suspended, dormant or deleted.';
