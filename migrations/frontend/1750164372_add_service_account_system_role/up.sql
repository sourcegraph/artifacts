INSERT INTO roles (created_at, system, name, tenant_id)
SELECT
  '2025-06-17 14:47:24.127459+00' AS created_at,
  true AS system,
  'SERVICE_ACCOUNT' AS name,
  tenants.id AS tenant_id
FROM tenants
ON CONFLICT (name, tenant_id) DO UPDATE SET system = true;
