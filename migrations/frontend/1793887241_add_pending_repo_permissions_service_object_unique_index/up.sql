-- Replaces pending_repo_permissions_service_perm_object_unique, which leads with
-- the permission column that code no longer reads. The permission column and the
-- old constraint are dropped in a later release, once no running code uses them.
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS pending_repo_permissions_service_object_unique
    ON pending_repo_permissions (service_type, service_id, repo_id, tenant_id, bind_id);
