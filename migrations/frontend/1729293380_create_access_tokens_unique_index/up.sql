CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS access_tokens_tnt_id ON access_tokens (value_sha256, tenant_id);
