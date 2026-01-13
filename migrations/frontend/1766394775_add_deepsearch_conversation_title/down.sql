-- Remove title column from deepsearch_conversations
ALTER TABLE deepsearch_conversations DROP COLUMN IF EXISTS title;
