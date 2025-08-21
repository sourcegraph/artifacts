-- Undo the changes made in the up migration
-- Revert the deepsearch_questions migration by truncating the table
-- This removes all the migrated data with snake_case conversion
TRUNCATE TABLE deepsearch_questions;

-- Re-apply the original migration logic without the snake_case conversion
-- This restores the previous state where data was stored with camelCase keys
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
