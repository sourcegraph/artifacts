CREATE INDEX CONCURRENTLY IF NOT EXISTS repository_fetch_history_telemetry_unexported
ON repository_fetch_history (tenant_id, id)
WHERE telemetry_exported_at IS NULL;
