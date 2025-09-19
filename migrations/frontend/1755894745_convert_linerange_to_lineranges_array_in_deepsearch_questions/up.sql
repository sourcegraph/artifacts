-- Convert lineRange to lineRanges (array) in deepsearch_questions sources metadata
ALTER TABLE deepsearch_conversations DISABLE TRIGGER USER;
ALTER TABLE deepsearch_questions DISABLE TRIGGER USER;
UPDATE deepsearch_questions
SET data = jsonb_set(
    data,
    '{sources}',
    (
        SELECT jsonb_agg(
            CASE
                WHEN source->'metadata'->'lineRange' IS NOT NULL THEN
                    jsonb_set(
                        source,
                        '{metadata}',
                        jsonb_set(
                            (source->'metadata') - 'lineRange',
                            '{lineRanges}',
                            jsonb_build_array(source->'metadata'->'lineRange')
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
    WHERE source->'metadata'->'lineRange' IS NOT NULL
);

ALTER TABLE deepsearch_questions ENABLE TRIGGER USER;
ALTER TABLE deepsearch_conversations ENABLE TRIGGER USER;
