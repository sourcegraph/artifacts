-- Add title column to deepsearch_conversations for fast sidebar queries
ALTER TABLE deepsearch_conversations ADD COLUMN IF NOT EXISTS title TEXT;

-- Backfill from first question per conversation: prefer generated title, fallback to question text.
-- Use NULLIF to treat empty strings as NULL so COALESCE falls back correctly.
UPDATE deepsearch_conversations c
SET title = q.derived_title
FROM (
    SELECT DISTINCT ON (conversation_id)
        conversation_id,
        COALESCE(
            NULLIF(data->>'title', ''),
            NULLIF(data->>'question', '')
        ) AS derived_title
    FROM deepsearch_questions
    ORDER BY conversation_id, created_at ASC
) q
WHERE q.conversation_id = c.id AND c.title IS NULL;
