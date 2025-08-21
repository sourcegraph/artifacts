-- Fix deepsearch question data with numeric SearchErrorKind values
-- Convert numeric enum values to string values expected by current Go code
-- 
-- Mapping:
-- 0 -> "TokenLimitExceeded"
-- 1 -> "Cancelled" 
-- 2 -> "RateLimitExceeded"
-- 3 -> "InternalError"

UPDATE deepsearch_questions 
SET data = jsonb_set(
    data,
    '{error,kind}',
    CASE 
        WHEN data->'error'->'kind' = '0'::jsonb THEN '"TokenLimitExceeded"'::jsonb
        WHEN data->'error'->'kind' = '1'::jsonb THEN '"Cancelled"'::jsonb
        WHEN data->'error'->'kind' = '2'::jsonb THEN '"RateLimitExceeded"'::jsonb
        WHEN data->'error'->'kind' = '3'::jsonb THEN '"InternalError"'::jsonb
        ELSE data->'error'->'kind'  -- Keep unchanged if already string or null
    END::jsonb
)
WHERE 
    data->'error'->'kind' IS NOT NULL
    AND jsonb_typeof(data->'error'->'kind') = 'number';

-- Also fix any errors nested in turns array
UPDATE deepsearch_questions 
SET data = jsonb_set(
    data,
    '{turns}',
    (
        SELECT jsonb_agg(
            CASE 
                WHEN turn->'error'->'kind' IS NOT NULL AND jsonb_typeof(turn->'error'->'kind') = 'number' THEN
                    jsonb_set(
                        turn,
                        '{error,kind}',
                        CASE 
                            WHEN turn->'error'->'kind' = '0'::jsonb THEN '"TokenLimitExceeded"'::jsonb
                            WHEN turn->'error'->'kind' = '1'::jsonb THEN '"Cancelled"'::jsonb
                            WHEN turn->'error'->'kind' = '2'::jsonb THEN '"RateLimitExceeded"'::jsonb
                            WHEN turn->'error'->'kind' = '3'::jsonb THEN '"InternalError"'::jsonb
                            ELSE turn->'error'->'kind'
                        END::jsonb
                    )
                ELSE turn
            END
        )
        FROM jsonb_array_elements(data->'turns') AS turn
    )
)
WHERE 
    data->'turns' IS NOT NULL 
    AND jsonb_typeof(data->'turns') = 'array'
    AND EXISTS (
        SELECT 1 
        FROM jsonb_array_elements(data->'turns') AS turn 
        WHERE turn->'error'->'kind' IS NOT NULL 
        AND jsonb_typeof(turn->'error'->'kind') = 'number'
    );
