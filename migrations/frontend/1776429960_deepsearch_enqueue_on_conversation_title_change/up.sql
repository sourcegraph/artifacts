-- Re-index questions when their conversation title changes, since the title
-- is part of deepsearch_search_index.search_text.
CREATE OR REPLACE FUNCTION deepsearch_enqueue_conversation_for_search()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO deepsearch_search_queue (
        question_id,
        tenant_id,
        queued_at,
        process_after,
        latest_question_updated_at
    )
    SELECT q.id, q.tenant_id, now(), NULL, now()
    FROM deepsearch_questions q
    WHERE q.conversation_id = NEW.id
      AND q.status != 'processing'
    ON CONFLICT (tenant_id, question_id) DO UPDATE SET
        latest_question_updated_at = EXCLUDED.latest_question_updated_at,
        queued_at                  = EXCLUDED.queued_at,
        process_after              = EXCLUDED.process_after,
        state                      = 'queued',
        started_at                 = NULL,
        cancel                     = false;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS deepsearch_conversations_title_search_queue_trg ON deepsearch_conversations;
CREATE TRIGGER deepsearch_conversations_title_search_queue_trg
    AFTER UPDATE OF title ON deepsearch_conversations
    FOR EACH ROW
    WHEN (OLD.title IS DISTINCT FROM NEW.title)
    EXECUTE FUNCTION deepsearch_enqueue_conversation_for_search();
