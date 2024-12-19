-- Make sure we start with at least 2 to leave room for the default tenant.
CREATE SEQUENCE IF NOT EXISTS tenants_id_seq AS integer START WITH 2;

ALTER TABLE tenants ALTER COLUMN id SET DEFAULT nextval('tenants_id_seq');

-- Adjust the sequence to match the current maximum value in the column.
SELECT setval('tenants_id_seq', COALESCE(MAX(id), 1)) FROM tenants;

-- Ensure the sequence is owned by the column (for cleanup on table drop).
ALTER SEQUENCE tenants_id_seq OWNED BY tenants.id;
