ALTER TABLE telemetry_events_export_queue ALTER COLUMN id SET DATA TYPE TEXT USING id::text;
