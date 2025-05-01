CREATE INDEX CONCURRENTLY IF NOT EXISTS telemetry_events_export_queue_export_order ON telemetry_events_export_queue (timestamp) WHERE exported_at IS NULL;
