-- Remove the column and index added by the up migration
DROP INDEX IF EXISTS changesets_auto_merge_method;
ALTER TABLE changesets DROP COLUMN IF EXISTS auto_merge_method;
