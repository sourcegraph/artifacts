-- Older code only understands file/line discussions. These cached PR-wide
-- discussions can be fetched again after upgrading.
DELETE FROM change_request_review_threads AS t
WHERE to_jsonb(t)->>'kind' IN ('GENERAL', 'REVIEW');

DROP INDEX IF EXISTS change_request_review_threads_chronological;
ALTER TABLE change_request_review_threads
    DROP COLUMN IF EXISTS kind,
    DROP COLUMN IF EXISTS created_at,
    DROP COLUMN IF EXISTS review_state,
    DROP COLUMN IF EXISTS review_commit_sha,
    DROP COLUMN IF EXISTS original_context;
ALTER TABLE change_requests DROP COLUMN IF EXISTS discussions_synced_at;
