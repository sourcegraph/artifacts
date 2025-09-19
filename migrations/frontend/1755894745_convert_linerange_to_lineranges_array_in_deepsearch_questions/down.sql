-- Revert lineRanges (array) back to lineRange in deepsearch_questions sources metadata
ALTER TABLE deepsearch_questions DISABLE TRIGGER USER;
ALTER TABLE deepsearch_conversations DISABLE TRIGGER USER;
UPDATE deepsearch_questions
SET data = jsonb_set(
    data,
    '{sources}',
    (
        SELECT jsonb_agg(
            CASE
                WHEN source->'metadata'->'lineRanges' IS NOT NULL
                     AND jsonb_array_length(source->'metadata'->'lineRanges') > 0 THEN
                    jsonb_set(
                        source,
                        '{metadata}',
                        jsonb_set(
                            (source->'metadata') - 'lineRanges',
                            '{lineRange}',
                            (source->'metadata'->'lineRanges'->0)
                        )
                    )
                ELSE source
            END
        )
        FROM jsonb_array_elements(data->'sources') AS source
    )
)
WHERE EXISTS (
    SELECT 1
    FROM jsonb_array_elements(data->'sources') AS source
    WHERE source->'metadata'->'lineRanges' IS NOT NULL
);
ALTER TABLE deepsearch_questions ENABLE TRIGGER USER;
ALTER TABLE deepsearch_conversations ENABLE TRIGGER USER;
