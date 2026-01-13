DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_entitlement_usage;
DROP TABLE IF EXISTS deepsearch_entitlement_usage;

ALTER TYPE entitlement_type RENAME TO entitlement_type_old;

CREATE TYPE entitlement_type AS ENUM ('completion_credits');

ALTER TABLE entitlements
    ALTER COLUMN type TYPE entitlement_type
    USING type::text::entitlement_type;

DROP TYPE entitlement_type_old;
