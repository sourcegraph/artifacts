-- Add scopes column as a text array with empty array as default
ALTER TABLE user_external_accounts
ADD COLUMN IF NOT EXISTS scopes text[] DEFAULT '{}' NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN user_external_accounts.scopes IS
'OAuth scopes granted to the token. Extracted from auth_data for efficient querying without decryption. Empty array for non-OAuth accounts or when scopes are unknown.';
