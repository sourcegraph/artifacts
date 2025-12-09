-- Drop the column
ALTER TABLE user_external_accounts
DROP COLUMN IF EXISTS scopes;
