-- Remove the unique constraint
ALTER TABLE batch_spec_library_variables 
DROP CONSTRAINT IF EXISTS batch_spec_library_variables_record_name_unique;

-- Note: We cannot restore the deleted duplicate entries as we don't know 
-- their exact values. This migration is not fully reversible.
