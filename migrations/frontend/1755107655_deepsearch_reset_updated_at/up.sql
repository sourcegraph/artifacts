
-- Apply the fixes
ALTER TABLE deepsearch_conversations DISABLE TRIGGER USER;
ALTER TABLE deepsearch_questions DISABLE TRIGGER USER;

UPDATE deepsearch_questions
SET
    updated_at = created_at;

UPDATE deepsearch_conversations
SET
    updated_at = created_at;

ALTER TABLE deepsearch_questions ENABLE TRIGGER USER;
ALTER TABLE deepsearch_conversations ENABLE TRIGGER USER;
