DROP INDEX IF EXISTS deepsearch_conversation_views_user_first_viewed;

ALTER TABLE deepsearch_conversation_views
    DROP COLUMN IF EXISTS first_viewed_at;
