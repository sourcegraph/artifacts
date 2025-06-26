DROP TABLE IF EXISTS deepsearch_conversations CASCADE;

DROP FUNCTION IF EXISTS update_deepsearch_conversations_updated_at();

DROP TRIGGER IF EXISTS update_deepsearch_conversations_updated_at ON deepsearch_conversations;
