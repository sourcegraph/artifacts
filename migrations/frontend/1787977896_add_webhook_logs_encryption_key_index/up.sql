CREATE INDEX CONCURRENTLY IF NOT EXISTS webhook_logs_encryption_key_id_idx
    ON webhook_logs (encryption_key_id);
