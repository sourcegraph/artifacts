CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS lsif_dependency_repos_unique_scheme_name_tnt ON lsif_dependency_repos (scheme, name, tenant_id);
