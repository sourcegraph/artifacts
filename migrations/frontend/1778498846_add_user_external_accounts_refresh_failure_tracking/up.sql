ALTER TABLE user_external_accounts
    ADD COLUMN IF NOT EXISTS refresh_failure_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN user_external_accounts.refresh_failure_at IS
    'Timestamp of the first OAuth refresh failure observed against the current refresh_token. Set on the first failure and reset to NULL whenever auth_data is rewritten (successful refresh or browser re-auth). Used together with a minimum-interval check to ride out provider eventual-consistency lags before clearing a refresh_token.';
