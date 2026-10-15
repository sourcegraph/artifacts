CREATE INDEX CONCURRENTLY IF NOT EXISTS notifications_tenant_kind_idx
ON notifications (tenant_id, kind)
WHERE kind <> '';
