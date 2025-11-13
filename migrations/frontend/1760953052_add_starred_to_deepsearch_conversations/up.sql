ALTER TABLE deepsearch_conversations ADD COLUMN IF NOT EXISTS is_starred BOOLEAN NOT NULL DEFAULT false;
