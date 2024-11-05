CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS repo_tnt_id ON repo (name, tenant_id);
