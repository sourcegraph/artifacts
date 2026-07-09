ALTER TABLE deepsearch_conversations
ADD COLUMN IF NOT EXISTS data jsonb;
