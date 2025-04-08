DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entitlement_type') THEN
        CREATE TYPE entitlement_type AS ENUM ('completion_credits');
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS entitlements (
    id serial PRIMARY KEY,
    name text NOT NULL,
    type entitlement_type NOT NULL,
    "limit" integer NOT NULL,
    "window" interval NOT NULL,
    is_default boolean NOT NULL DEFAULT false,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

COMMENT ON COLUMN entitlements.type IS
    'The type of entitlement. Currently supports "completion_credits" with more types to be added in the future. Must not be updated after insert.';

-- Only one default entitlement per type.
CREATE UNIQUE INDEX IF NOT EXISTS unique_entitlement_type_default_idx ON entitlements (type, tenant_id) WHERE (is_default);

-- User->Entitlement
CREATE TABLE IF NOT EXISTS entitlement_grants (
    entitlement_id integer NOT NULL REFERENCES entitlements(id) ON DELETE CASCADE,
    user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (entitlement_id, user_id),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

-- Each user can only have one entitlement of a given type.
-- FUTURE: Maybe we don't need this, and we can just rely on the store layer to
-- enforce this invariant, as this is a bit awkward to do here.
CREATE OR REPLACE FUNCTION check_user_entitlement_grant_type() RETURNS TRIGGER AS $$
BEGIN
    -- Check if user already has an entitlement of this type
    IF EXISTS (
        SELECT 1
        FROM entitlement_grants eg
        JOIN entitlements e1 ON eg.entitlement_id = e1.id
        JOIN entitlements e2 ON NEW.entitlement_id = e2.id
        WHERE eg.user_id = NEW.user_id
          AND e1.type = e2.type
          AND eg.entitlement_id <> NEW.entitlement_id
        FOR UPDATE
    ) THEN
        RAISE EXCEPTION 'User already has an entitlement of this type';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_single_entitlement_grant_type_per_user ON entitlement_grants;
CREATE TRIGGER enforce_single_entitlement_grant_type_per_user
BEFORE INSERT OR UPDATE ON entitlement_grants
FOR EACH ROW EXECUTE FUNCTION check_user_entitlement_grant_type();

CREATE INDEX IF NOT EXISTS entitlement_grants_user_id_idx ON entitlement_grants(user_id);

-- Enable RLS on both tables
ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE entitlement_grants ENABLE ROW LEVEL SECURITY;

-- Create tenant isolation policies
DROP POLICY IF EXISTS tenant_isolation_policy ON entitlements;
CREATE POLICY tenant_isolation_policy ON entitlements AS PERMISSIVE FOR ALL TO PUBLIC
USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

DROP POLICY IF EXISTS tenant_isolation_policy ON entitlement_grants;
CREATE POLICY tenant_isolation_policy ON entitlement_grants AS PERMISSIVE FOR ALL TO PUBLIC
USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
