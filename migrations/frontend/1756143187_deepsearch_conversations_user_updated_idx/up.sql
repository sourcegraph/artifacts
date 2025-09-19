CREATE INDEX CONCURRENTLY IF NOT EXISTS deepsearch_conversations_user_updated_idx 
ON deepsearch_conversations (user_id, updated_at DESC);
