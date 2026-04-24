UPDATE deepsearch_questions
SET data = data - 'ui_data'
WHERE data ? 'ui_data';

UPDATE deepsearch_conversations
SET data = data - 'ui_data'
WHERE data ? 'ui_data';
