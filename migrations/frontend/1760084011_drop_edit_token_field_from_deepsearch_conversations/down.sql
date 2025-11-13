ALTER TABLE IF EXISTS deepsearch_conversations ADD COLUMN IF NOT EXISTS edit_token uuid DEFAULT gen_random_uuid();
