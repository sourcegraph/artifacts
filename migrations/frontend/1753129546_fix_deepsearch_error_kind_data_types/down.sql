-- WARNING: This down migration converts ALL string SearchErrorKind values back to numeric
-- This includes values that may have originally been strings before the up migration
-- Only run this if you're certain you want to revert ALL data to numeric format
--
-- Mapping (reverse):
-- "TokenLimitExceeded" -> 0
-- "Cancelled" -> 1
-- "RateLimitExceeded" -> 2
-- "InternalError" -> 3
--
-- NOTE: This assumes you're also reverting code changes that expect numeric values

UPDATE deepsearch_questions 
SET data = jsonb_set(
    data,
    '{error,kind}',
    CASE 
        WHEN data->'error'->'kind' = '"TokenLimitExceeded"'::jsonb THEN '0'::jsonb
        WHEN data->'error'->'kind' = '"Cancelled"'::jsonb THEN '1'::jsonb
        WHEN data->'error'->'kind' = '"RateLimitExceeded"'::jsonb THEN '2'::jsonb
        WHEN data->'error'->'kind' = '"InternalError"'::jsonb THEN '3'::jsonb
        ELSE data->'error'->'kind'  -- Keep unchanged if not recognized
    END::jsonb
)
WHERE 
    data->'error'->'kind' IS NOT NULL
    AND jsonb_typeof(data->'error'->'kind') = 'string'
    AND data->'error'->'kind'::text IN ('"TokenLimitExceeded"', '"Cancelled"', '"RateLimitExceeded"', '"InternalError"');

-- Also revert any errors nested in turns array
UPDATE deepsearch_questions 
SET data = jsonb_set(
    data,
    '{turns}',
    (
        SELECT jsonb_agg(
            CASE 
                WHEN turn->'error'->'kind' IS NOT NULL AND jsonb_typeof(turn->'error'->'kind') = 'string' THEN
                    jsonb_set(
                        turn,
                        '{error,kind}',
                        CASE 
                            WHEN turn->'error'->'kind' = '"TokenLimitExceeded"'::jsonb THEN '0'::jsonb
                            WHEN turn->'error'->'kind' = '"Cancelled"'::jsonb THEN '1'::jsonb
                            WHEN turn->'error'->'kind' = '"RateLimitExceeded"'::jsonb THEN '2'::jsonb
                            WHEN turn->'error'->'kind' = '"InternalError"'::jsonb THEN '3'::jsonb
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
        AND jsonb_typeof(turn->'error'->'kind') = 'string'
        AND turn->'error'->'kind'::text IN ('"TokenLimitExceeded"', '"Cancelled"', '"RateLimitExceeded"', '"InternalError"')
    );
