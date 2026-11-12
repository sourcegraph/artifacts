DROP TABLE IF EXISTS codeintel_destination_write_history;
ALTER TABLE codeintel_destination_write_jobs DROP COLUMN IF EXISTS produce_started_at;
