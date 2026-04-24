-- Remove the kind CHECK constraint added by the up migration.
ALTER TABLE user_external_accounts
    DROP CONSTRAINT IF EXISTS user_external_accounts_kind_valid;

-- Recreate the original unique index that was dropped in the up migration.
-- Column order must match the original definition (tenant_id last) to avoid
-- schema drift detection failures.
CREATE UNIQUE INDEX IF NOT EXISTS user_external_accounts_account
    ON user_external_accounts (service_type, service_id, client_id, account_id, tenant_id)
    WHERE deleted_at IS NULL;
