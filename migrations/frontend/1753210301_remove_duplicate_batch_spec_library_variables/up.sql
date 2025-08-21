-- Remove duplicate batch spec library variables, keeping the newer entries
-- This fixes the issue where migration 1752580919 created duplicates

-- For each (batch_spec_library_record_id, name) combination, keep only the latest entry (highest ID)
DELETE FROM batch_spec_library_variables 
WHERE id NOT IN (
    SELECT MAX(id)
    FROM batch_spec_library_variables
    GROUP BY batch_spec_library_record_id, name
);

-- Add unique constraint to prevent future duplicates (only if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'batch_spec_library_variables_record_name_unique'
    ) THEN
        ALTER TABLE batch_spec_library_variables 
        ADD CONSTRAINT batch_spec_library_variables_record_name_unique 
        UNIQUE (batch_spec_library_record_id, name);
    END IF;
END $$;
