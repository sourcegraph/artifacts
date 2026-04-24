INSERT INTO roles (system, name, tenant_id)
SELECT
  true AS system,
  'SERVICE_ACCOUNT' AS name,
  tenants.id AS tenant_id
FROM tenants
ON CONFLICT (name, tenant_id) DO UPDATE SET system = true;
