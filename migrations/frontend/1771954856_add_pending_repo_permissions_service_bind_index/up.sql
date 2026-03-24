CREATE INDEX CONCURRENTLY IF NOT EXISTS pending_repo_permissions_service_bind
    ON pending_repo_permissions (service_type, service_id, bind_id);
