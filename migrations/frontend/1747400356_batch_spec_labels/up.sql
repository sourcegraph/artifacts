-- Add labels column to batch_spec_library_records table with empty array default
ALTER TABLE batch_spec_library_records ADD COLUMN IF NOT EXISTS labels text[] DEFAULT '{}'::TEXT[];

-- Add comment explaining the new column
COMMENT ON COLUMN batch_spec_library_records.labels IS 'Array of labels associated with this batch spec, such as "featured". Used for filtering and categorization.';
