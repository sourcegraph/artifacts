-- Truncate existing deepsearch_questions data
TRUNCATE TABLE deepsearch_questions;

-- Re-migrate data from deepsearch_conversations with proper camelCase to snake_case conversion
INSERT INTO deepsearch_questions(conversation_id, created_at, updated_at, data, tenant_id)
SELECT
    dc.id AS conversation_id,
    dc.created_at,
    dc.updated_at,
    -- Convert camelCase keys to snake_case and restructure the JSON
    jsonb_build_object('question', question_data.value ->> 'question', 'created_at', dc.created_at, 'updated_at', dc.updated_at, 'completed', question_data.value -> 'completed', 'title', question_data.value -> 'title', 'answer', question_data.value -> 'answer', 'error', CASE WHEN question_data.value -> 'error' IS NOT NULL THEN
            jsonb_build_object('title', question_data.value -> 'error' ->> 'title', 'message', question_data.value -> 'error' ->> 'message', 'details', question_data.value -> 'error' ->> 'details', 'kind', CASE WHEN question_data.value -> 'error' -> 'kind' = '0'::jsonb THEN
                    'TokenLimitExceeded'
                WHEN question_data.value -> 'error' -> 'kind' = '1'::jsonb THEN
                    'Cancelled'
                WHEN question_data.value -> 'error' -> 'kind' = '2'::jsonb THEN
                    'RateLimitExceeded'
                WHEN question_data.value -> 'error' -> 'kind' = '3'::jsonb THEN
                    'InternalError'
                ELSE
                    COALESCE(question_data.value -> 'error' ->> 'kind', 'InternalError')
                END)
        ELSE
            NULL
        END, 'sources', question_data.value -> 'sources', 'turns', CASE WHEN question_data.value -> 'turns' IS NOT NULL THEN
        (
            SELECT
                jsonb_agg(jsonb_build_object('reasoning', turn_item ->> 'reasoning', 'tool_calls', CASE WHEN turn_item -> 'toolCalls' IS NOT NULL THEN
                        (
                            SELECT
                                jsonb_agg(jsonb_build_object('tool_name', tool_call ->> 'toolName', 'args', tool_call -> 'args', 'id', tool_call ->> 'id'))
                        FROM jsonb_array_elements(turn_item -> 'toolCalls') AS tool_call)
                        ELSE
                            NULL
                        END, 'tool_results', CASE WHEN turn_item -> 'toolResults' IS NOT NULL THEN
                        (
                            SELECT
                                jsonb_agg(jsonb_build_object('tool_name', tool_result ->> 'toolName', 'result', tool_result -> 'result', 'id', tool_result ->> 'id', 'error', tool_result -> 'error'))
                            FROM jsonb_array_elements(turn_item -> 'toolResults') AS tool_result)
                        ELSE
                            NULL
                        END, 'error', CASE WHEN turn_item -> 'error' IS NOT NULL THEN
                            jsonb_build_object('title', turn_item -> 'error' ->> 'title', 'message', turn_item -> 'error' ->> 'message', 'details', turn_item -> 'error' ->> 'details', 'kind', CASE WHEN turn_item -> 'error' -> 'kind' = '0'::jsonb THEN
                                    'TokenLimitExceeded'
                                WHEN turn_item -> 'error' -> 'kind' = '1'::jsonb THEN
                                    'Cancelled'
                                WHEN turn_item -> 'error' -> 'kind' = '2'::jsonb THEN
                                    'RateLimitExceeded'
                                WHEN turn_item -> 'error' -> 'kind' = '3'::jsonb THEN
                                    'InternalError'
                                ELSE
                                    COALESCE(turn_item -> 'error' ->> 'kind', 'InternalError')
                                END)
                        ELSE
                            NULL
                        END, 'stats', CASE WHEN turn_item -> 'stats' IS NOT NULL THEN
                            jsonb_build_object('time_millis', COALESCE(turn_item -> 'stats' -> 'timeMillis', '0'::jsonb), 'tool_calls', COALESCE(turn_item -> 'stats' -> 'toolCalls', '0'::jsonb), 'total_input_tokens', COALESCE(turn_item -> 'stats' -> 'totalInputTokens', '0'::jsonb), 'cached_tokens', COALESCE(turn_item -> 'stats' -> 'cachedTokens', '0'::jsonb), 'cache_creation_input_tokens', COALESCE(turn_item -> 'stats' -> 'cacheCreationInputTokens', '0'::jsonb), 'prompt_tokens', COALESCE(turn_item -> 'stats' -> 'promptTokens', '0'::jsonb), 'completion_tokens', COALESCE(turn_item -> 'stats' -> 'completionTokens', '0'::jsonb), 'total_tokens', COALESCE(turn_item -> 'stats' -> 'totalTokens', '0'::jsonb), 'credits', COALESCE(turn_item -> 'stats' -> 'credits', '0'::jsonb))
                        ELSE
                            NULL
                        END, 'timestamp', turn_item -> 'timestamp', 'role', CASE WHEN turn_item ->> 'fromUser' = 'true' THEN
                            '"user"'::jsonb
                        ELSE
                            '"assistant"'::jsonb
                        END))
                FROM jsonb_array_elements(question_data.value -> 'turns') AS turn_item)
        ELSE
            NULL
        END, 'stats', CASE WHEN question_data.value -> 'stats' IS NOT NULL THEN
            jsonb_build_object('time_millis', COALESCE(question_data.value -> 'stats' -> 'timeMillis', '0'::jsonb), 'tool_calls', COALESCE(question_data.value -> 'stats' -> 'toolCalls', '0'::jsonb), 'total_input_tokens', COALESCE(question_data.value -> 'stats' -> 'totalInputTokens', '0'::jsonb), 'cached_tokens', COALESCE(question_data.value -> 'stats' -> 'totalCachedTokens', '0'::jsonb), 'cache_creation_input_tokens', COALESCE(question_data.value -> 'stats' -> 'totalCacheCreationInputTokens', '0'::jsonb), 'prompt_tokens', COALESCE(question_data.value -> 'stats' -> 'totalPromptTokens', '0'::jsonb), 'completion_tokens', COALESCE(question_data.value -> 'stats' -> 'totalCompletionTokens', '0'::jsonb), 'total_tokens', COALESCE(question_data.value -> 'stats' -> 'totalTokens', '0'::jsonb), 'credits', COALESCE(question_data.value -> 'stats' -> 'credits', '0'::jsonb))
        ELSE
            jsonb_build_object('time_millis', '0'::jsonb, 'tool_calls', '0'::jsonb, 'total_input_tokens', '0'::jsonb, 'cached_tokens', '0'::jsonb, 'cache_creation_input_tokens', '0'::jsonb, 'prompt_tokens', '0'::jsonb, 'completion_tokens', '0'::jsonb, 'total_tokens', '0'::jsonb, 'credits', '0'::jsonb)
        END, 'suggested_followups', COALESCE(question_data.value -> 'suggestedFollowups', '[]'::jsonb), 'ui_data', question_data.value) AS data,
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

ALTER TABLE deepsearch_conversations DISABLE TRIGGER USER;

ALTER TABLE deepsearch_questions DISABLE TRIGGER USER;

UPDATE
    deepsearch_conversations
SET
    updated_at = created_at;

ALTER TABLE deepsearch_conversations ENABLE TRIGGER USER;

ALTER TABLE deepsearch_questions ENABLE TRIGGER USER;

-- Delete orphaned deepsearch_conversations that don't have corresponding entries in deepsearch_questions
DELETE FROM deepsearch_conversations 
WHERE NOT EXISTS (
    SELECT 1 
    FROM deepsearch_questions 
    WHERE deepsearch_questions.conversation_id = deepsearch_conversations.id
);
