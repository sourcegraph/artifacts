CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS user_external_accounts_account_tnt ON user_external_accounts (service_type, service_id, client_id, account_id, tenant_id) WHERE deleted_at IS NULL;
