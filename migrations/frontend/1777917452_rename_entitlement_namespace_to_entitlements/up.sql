-- Rename the RBAC namespace 'ENTITLEMENT' to 'ENTITLEMENTS' to match the
-- updated schema in internal/rbac/schema.yaml. We update in place so that the
-- permission rows keep their primary keys, which preserves all existing
-- role_permissions and user grants. Without this, rbac.UpdatePermissions on
-- startup would delete the old rows (cascading the role assignments) and
-- recreate the new ones, only re-granting the default system roles.
UPDATE permissions
SET namespace = 'ENTITLEMENTS'
WHERE namespace = 'ENTITLEMENT';
