-- undoes 1733926716_drop_tenant which is now a noop

CREATE TABLE IF NOT EXISTS tenants (
    id bigint PRIMARY KEY,
    name text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    workspace_id uuid NOT NULL,
    display_name text,
    state tenant_state NOT NULL DEFAULT 'active'::tenant_state,
    external_url text NOT NULL DEFAULT '',
    CONSTRAINT tenants_name_key UNIQUE (name),
    CONSTRAINT tenants_workspace_id_key UNIQUE (workspace_id),
    CONSTRAINT tenant_name_length CHECK (char_length(name) <= 32 AND char_length(name) >= 3),
    CONSTRAINT tenant_name_valid_chars CHECK (name ~ '^[a-z](?:[a-z0-9\_-])*[a-z0-9]$'::text),
    CONSTRAINT tenants_external_url_check CHECK (lower(external_url) = external_url)
);

COMMENT ON TABLE tenants IS 'The table that holds all tenants known to the instance. In enterprise instances, this table will only contain the "default" tenant.';
COMMENT ON COLUMN tenants.id IS 'The ID of the tenant. To keep tenants globally addressable, and be able to move them aronud instances more easily, the ID is NOT a serial and has to be specified explicitly. The creator of the tenant is responsible for choosing a unique ID, if it cares.';
COMMENT ON COLUMN tenants.name IS 'The name of the tenant. This may be displayed to the user and must be unique.';

INSERT INTO tenants (id, name, workspace_id, created_at, updated_at) VALUES (1, 'default', '6a6b043c-ffed-42ec-b1f4-abc231cd7222', '2024-09-28 09:41:00.000000+00', '2024-09-28 09:41:00.000000+00') ON CONFLICT DO NOTHING;

-- Make sure we start with at least 2 to leave room for the default tenant.
CREATE SEQUENCE IF NOT EXISTS tenants_id_seq AS integer START WITH 2;

ALTER TABLE tenants ALTER COLUMN id SET DEFAULT nextval('tenants_id_seq');

-- Adjust the sequence to match the current maximum value in the column.
SELECT setval('tenants_id_seq', COALESCE(MAX(id), 1)) FROM tenants;

-- Ensure the sequence is owned by the column (for cleanup on table drop).
ALTER SEQUENCE tenants_id_seq OWNED BY tenants.id;
