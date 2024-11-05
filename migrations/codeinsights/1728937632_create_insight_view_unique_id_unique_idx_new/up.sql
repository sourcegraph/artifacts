CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS insight_view_unique_id_unique_idx_new ON insight_view (unique_id, tenant_id);
