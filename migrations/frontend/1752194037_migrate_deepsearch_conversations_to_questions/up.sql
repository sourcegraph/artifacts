-- Migrate existing deepsearch_conversations data to deepsearch_questions
-- Each conversation's ui_data contains a Conversation object with questions array
-- We extract each question and create a separate row in deepsearch_questions
INSERT INTO deepsearch_questions(conversation_id, created_at, updated_at, data, tenant_id)
SELECT
    dc.id AS conversation_id,
    dc.created_at,
    dc.updated_at,
    question_data.value #- '{id}' AS data,
    dc.tenant_id
FROM
    deepsearch_conversations dc
    CROSS JOIN LATERAL (
        SELECT
            jsonb_array_elements(dc.data -> 'ui_data' -> 'questions') AS value
        WHERE
            jsonb_typeof(dc.data -> 'ui_data' -> 'questions') = 'array') question_data
WHERE
    dc.data -> 'ui_data' -> 'questions' IS NOT NULL
    AND jsonb_typeof(dc.data -> 'ui_data' -> 'questions') = 'array'
    AND jsonb_array_length(dc.data -> 'ui_data' -> 'questions') > 0;
