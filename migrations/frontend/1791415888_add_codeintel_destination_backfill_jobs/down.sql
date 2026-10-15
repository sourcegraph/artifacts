ALTER TABLE codeintel_destination_write_jobs DROP COLUMN IF EXISTS backfill_round;
DROP TABLE IF EXISTS codeintel_destination_backfill_rounds;
DROP TABLE IF EXISTS codeintel_destination_backfill_jobs;
