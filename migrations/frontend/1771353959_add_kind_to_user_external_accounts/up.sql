ALTER TABLE user_external_accounts
    ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'AUTH';

ALTER TABLE user_external_accounts
    DROP CONSTRAINT IF EXISTS user_external_accounts_kind_not_empty;
ALTER TABLE user_external_accounts
    ADD CONSTRAINT user_external_accounts_kind_not_empty CHECK (BTRIM(kind) <> '');

COMMENT ON COLUMN user_external_accounts.kind IS
    'Purpose of this external account: AUTH (authentication), BATCH_CHANGES (batch changes credentials), etc.';
