-- Seek and return an ordered page for one ancestor without scanning all its links.
-- Include tenant_id so the tenant isolation policy permits an index-only scan.
CREATE INDEX CONCURRENTLY IF NOT EXISTS scip_nearest_uploads_links_repository_ancestor_commit
ON scip_nearest_uploads_links (repository_id, ancestor_commit_bytea, commit_bytea)
INCLUDE (tenant_id);
