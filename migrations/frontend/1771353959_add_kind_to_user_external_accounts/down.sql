ALTER TABLE user_external_accounts
    DROP CONSTRAINT IF EXISTS user_external_accounts_kind_not_empty;

ALTER TABLE user_external_accounts
    DROP COLUMN IF EXISTS kind;
