CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS repo_name_lower_unique_tmp ON repo (name_lower, tenant_id);
