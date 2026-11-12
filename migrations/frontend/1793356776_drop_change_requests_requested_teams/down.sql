ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS requested_teams TEXT[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS change_requests_requested_teams_idx
    ON change_requests USING GIN (requested_teams);
