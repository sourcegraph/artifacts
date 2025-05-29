-- Remove the labels column from batch_spec_library_records table
ALTER TABLE batch_spec_library_records DROP COLUMN IF EXISTS labels;
