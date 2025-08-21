-- Reverse migration: remove question data from deepsearch_questions table
-- This removes the migrated data that was created during the up migration
-- The original data in deepsearch_conversations.data->'ui_data'->'questions' remains intact

DELETE FROM deepsearch_questions 
WHERE conversation_id IN (
    SELECT id FROM deepsearch_conversations 
    WHERE data->'ui_data'->'questions' IS NOT NULL 
      AND jsonb_typeof(data->'ui_data'->'questions') = 'array'
      AND jsonb_array_length(data->'ui_data'->'questions') > 0
);
