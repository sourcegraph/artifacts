CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS users_billing_customer_id_tnt ON users (billing_customer_id, tenant_id) WHERE deleted_at IS NULL;
