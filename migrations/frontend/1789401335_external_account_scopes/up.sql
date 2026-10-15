ALTER TABLE user_external_accounts ADD COLUMN IF NOT EXISTS scopes text[];

COMMENT ON COLUMN user_external_accounts.scopes IS
    'Provider-granted OAuth scopes, independent of token refresh. NULL means unknown; an empty array means a known empty OAuth scope set. GitHub App permissions are not OAuth scopes.';
