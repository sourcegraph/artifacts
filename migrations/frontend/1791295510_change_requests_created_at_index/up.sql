CREATE INDEX CONCURRENTLY IF NOT EXISTS change_requests_created_at_idx
    ON change_requests (tenant_id, external_created_at, id);
