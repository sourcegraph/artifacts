-- Avoid fetching and decompressing the full PR snapshot for reviewer filtering.
-- Generation backfills existing rows and keeps old sync writers compatible.
ALTER TABLE change_requests
    ADD COLUMN IF NOT EXISTS requested_reviewer_data JSONB
    GENERATED ALWAYS AS (external_data->'requested_reviewers') STORED;

COMMENT ON COLUMN change_requests.requested_reviewer_data IS 'Requested reviewer identities from the GitHub snapshot, stored separately to avoid reading the full external_data payload when filtering.';
