-- The code host's aggregate review status, such as APPROVED, or NULL if the
-- code host reports none.
ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS review_status TEXT;
-- The latest approving or change-requesting review of each reviewer.
ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS reviews JSONB NOT NULL DEFAULT '[]';
