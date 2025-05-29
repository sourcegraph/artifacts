-- Add unique constraint on name, type, tenant_id to prevent duplicate entitlements of the same type
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'entitlements_name_type_tenant_unique'
    ) THEN
        ALTER TABLE entitlements ADD CONSTRAINT entitlements_name_type_tenant_unique UNIQUE (name, type, tenant_id);
    END IF;
END
$$;
