CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS repo_names_name_unique_idx_new ON repo_names (name, tenant_id);
