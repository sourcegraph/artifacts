-- Undo the changes made in the up migration
ALTER TABLE deepsearch_conversations DROP COLUMN IF EXISTS overrides;
