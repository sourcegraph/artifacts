CREATE UNIQUE INDEX IF NOT EXISTS user_external_accounts_user_kind
    ON user_external_accounts (tenant_id, user_id, service_type, service_id, client_id, account_id, kind)
    WHERE deleted_at IS NULL;
