-- Fix tool calls in deepsearch_questions by using the correct data from ui_data.turns

-- Create a temporary table to hold the questions that need fixing
CREATE TEMP TABLE questions_to_fix AS
SELECT
    id,
    data
FROM deepsearch_questions
WHERE
    data -> 'ui_data' IS NOT NULL
    AND data -> 'ui_data' -> 'turns' IS NOT NULL
    AND jsonb_typeof(data -> 'ui_data' -> 'turns') = 'array'
    AND data -> 'turns' IS NOT NULL
    AND jsonb_typeof(data -> 'turns') = 'array'
    AND (
        -- Check if any turn has poorly formatted tool calls
        EXISTS (
            SELECT 1
            FROM jsonb_array_elements(data -> 'turns') AS turn
            WHERE turn -> 'tool_calls' IS NOT NULL
              AND jsonb_typeof(turn -> 'tool_calls') = 'array'
              AND EXISTS (
                  SELECT 1
                  FROM jsonb_array_elements(turn -> 'tool_calls') AS tc
                  WHERE tc ? 'tool_name' OR tc ? 'args'
              )
        )
        OR
        -- Check if any turn has tool_results with invalid keys
        EXISTS (
            SELECT 1
            FROM jsonb_array_elements(data -> 'turns') AS turn
            WHERE turn -> 'tool_results' IS NOT NULL
              AND jsonb_typeof(turn -> 'tool_results') = 'array'
              AND EXISTS (
                  SELECT 1
                  FROM jsonb_array_elements(turn -> 'tool_results') AS tr
                  WHERE tr ? 'tool_name' OR tr ? 'result' or tr ? 'error'
              )
        )
        OR
        -- Check if there are ui_data turns with toolCalls but corresponding turns have null tool_calls
        EXISTS (
            SELECT 1
            FROM jsonb_array_elements(data -> 'ui_data' -> 'turns') AS ui_turn,
                 jsonb_array_elements(data -> 'turns') AS turn
            WHERE ui_turn ->> 'reasoning' = turn ->> 'reasoning'
              AND ui_turn -> 'toolCalls' IS NOT NULL
              AND jsonb_typeof(ui_turn -> 'toolCalls') = 'array'
              AND jsonb_array_length(ui_turn -> 'toolCalls') > 0
              AND turn -> 'tool_calls' IS NULL
        )
    );

-- Create a temporary table with the fixed data
CREATE TEMP TABLE fixed_questions AS
SELECT
    qtf.id,
    jsonb_set(
        qtf.data,
        '{turns}',
        (
            SELECT jsonb_agg(
                -- Build the new turn object
                jsonb_set(
                    jsonb_set(
                        turn,
                        '{tool_calls}',
                        coalesce(ui_turn -> 'toolCalls', '[]'::jsonb)
                    )   ,
                    '{tool_results}',
                    coalesce(ui_turn -> 'toolResults', '[]'::jsonb)
                )
            )
            FROM jsonb_array_elements(qtf.data -> 'turns') AS turn
            LEFT JOIN jsonb_array_elements(qtf.data -> 'ui_data' -> 'turns') AS ui_turn
            ON turn ->> 'reasoning' = ui_turn ->> 'reasoning'
        )
    ) AS fixed_data
FROM questions_to_fix qtf;


-- Convert tool calls arguments from object to string format
UPDATE fixed_questions
SET fixed_data = jsonb_set(
    fixed_data,
    '{turns}',
    (
        SELECT jsonb_agg(
            CASE
                WHEN turn -> 'tool_calls' IS NOT NULL AND jsonb_typeof(turn -> 'tool_calls') = 'array' AND jsonb_array_length(turn -> 'tool_calls') > 0 THEN
                    jsonb_set(
                        turn,
                        '{tool_calls}',
                        (
                            SELECT jsonb_agg(
                                CASE
                                    WHEN tc -> 'function' -> 'arguments' IS NOT NULL
                                         AND jsonb_typeof(tc -> 'function' -> 'arguments') = 'object' THEN
                                        jsonb_set(
                                            tc,
                                            '{function,arguments}',
                                            to_jsonb((tc -> 'function' -> 'arguments')::text)
                                        )
                                    ELSE tc
                                END
                            )
                            FROM jsonb_array_elements(turn -> 'tool_calls') AS tc
                        )
                    )
                ELSE turn
            END
        )
        FROM jsonb_array_elements(fixed_data -> 'turns') AS turn
    )
);

-- Apply the fixes
ALTER TABLE deepsearch_conversations DISABLE TRIGGER USER;
ALTER TABLE deepsearch_questions DISABLE TRIGGER USER;

UPDATE deepsearch_questions
SET
    data = fq.fixed_data
FROM fixed_questions fq
WHERE deepsearch_questions.id = fq.id;

ALTER TABLE deepsearch_conversations ENABLE TRIGGER USER;
ALTER TABLE deepsearch_questions ENABLE TRIGGER USER;

-- Clean up temporary tables
DROP TABLE questions_to_fix;
DROP TABLE fixed_questions;
