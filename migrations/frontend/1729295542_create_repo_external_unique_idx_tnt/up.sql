CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS repo_external_unique_idx_tnt ON repo (external_service_type, external_service_id, external_id, tenant_id);
