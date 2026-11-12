ALTER TABLE repository_fetch_history DROP COLUMN IF EXISTS telemetry_exported_at;
ALTER TABLE repository_fetch_history DROP COLUMN IF EXISTS external_connectivity_error;
