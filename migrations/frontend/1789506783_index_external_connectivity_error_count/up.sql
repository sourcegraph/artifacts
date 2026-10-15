CREATE INDEX CONCURRENTLY IF NOT EXISTS gitserver_repos_external_connectivity_errors_idx
ON gitserver_repos (tenant_id, repo_id)
WHERE consecutive_external_connectivity_errors >= 3;
