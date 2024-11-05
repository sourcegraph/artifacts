CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS users_username_tnt ON users (username, tenant_id) WHERE deleted_at IS NULL;
