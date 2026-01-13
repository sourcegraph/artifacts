ALTER TABLE user_credentials
    ADD COLUMN IF NOT EXISTS user_external_account_id INTEGER REFERENCES user_external_accounts(id) ON DELETE CASCADE;

-- Add comment for documentation
COMMENT ON COLUMN user_credentials.user_external_account_id IS
    'The ID of the user external account associated with the user credentials. Usually an Oauth token';
