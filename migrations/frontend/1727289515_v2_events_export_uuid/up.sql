-- Safe because all values here are UUID in text format already
ALTER TABLE telemetry_events_export_queue ALTER COLUMN id SET DATA TYPE UUID USING id::uuid;
