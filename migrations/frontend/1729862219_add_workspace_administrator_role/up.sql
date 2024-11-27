INSERT INTO roles (created_at, system, name, tenant_id)
SELECT
  '2024-10-30 11:54:24.127459+00' AS created_at,
  true AS system,
  'WORKSPACE_ADMINISTRATOR' AS name,
  tenants.id AS tenant_id
FROM tenants
ON CONFLICT (name, tenant_id) DO UPDATE SET system = true;
