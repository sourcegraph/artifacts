CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS metadata_metadata_unique_idx_new ON metadata (metadata, tenant_id);
