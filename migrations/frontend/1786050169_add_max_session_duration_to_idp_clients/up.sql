-- Maximum duration (in seconds) that an OAuth session for this client may
-- live since the user's original authentication, regardless of refresh token
-- rotation. NULL means no limit.
ALTER TABLE idp_clients ADD COLUMN IF NOT EXISTS max_session_duration_seconds INTEGER;
