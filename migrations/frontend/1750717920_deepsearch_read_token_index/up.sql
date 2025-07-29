CREATE INDEX IF NOT EXISTS deepsearch_conversations_read_token_idx ON deepsearch_conversations USING HASH (read_token);
