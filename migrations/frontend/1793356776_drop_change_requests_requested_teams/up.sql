-- Requested teams are stored by ID in change_request_requested_teams.
-- Dropping the column also drops change_requests_requested_teams_idx.
ALTER TABLE change_requests DROP COLUMN IF EXISTS requested_teams;
