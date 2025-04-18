CREATE TABLE IF NOT EXISTS tenants (
    id bigint PRIMARY KEY,
    name text UNIQUE NOT NULL CONSTRAINT tenant_name_length CHECK (char_length(name::text) <= 32 AND char_length(name::text) >= 3) CONSTRAINT tenant_name_valid_chars CHECK (name ~ '^[a-z](?:[a-z0-9\_-])*[a-z0-9]$'::text),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

COMMENT ON TABLE tenants IS 'The table that holds all tenants known to the instance. In enterprise instances, this table will only contain the "default" tenant.';
COMMENT ON COLUMN tenants.id IS 'The ID of the tenant. To keep tenants globally addressable, and be able to move them aronud instances more easily, the ID is NOT a serial and has to be specified explicitly. The creator of the tenant is responsible for choosing a unique ID, if it cares.';
COMMENT ON COLUMN tenants.name IS 'The name of the tenant. This may be displayed to the user and must be unique.';

-- For now, we create one default tenant for every instance. The id 1 is hard-coded in-application.
DO $$
BEGIN
  -- Check if the workspace_id column exists. In the case of using multiple database schemas
  -- in the same database, the table will already exist since every schema has a
  -- copy of tenants.
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema = 'public' AND table_name='tenants' AND column_name='workspace_id') THEN
    INSERT INTO tenants (id, name, workspace_id, created_at, updated_at) VALUES (1, 'default', '6a6b043c-ffed-42ec-b1f4-abc231cd7222', '2024-09-28 09:41:00.000000+00', '2024-09-28 09:41:00.000000+00') ON CONFLICT DO NOTHING;
  ELSE
    INSERT INTO tenants (id, name, created_at, updated_at) VALUES (1, 'default', '2024-09-28 09:41:00.000000+00', '2024-09-28 09:41:00.000000+00') ON CONFLICT DO NOTHING;
  END IF;
END $$;
