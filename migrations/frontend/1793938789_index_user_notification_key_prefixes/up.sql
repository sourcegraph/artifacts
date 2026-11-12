-- Bytewise key-prefix bounds support ownership cleanup for typed and legacy rows
-- under RLS, independently of the database's default collation.
CREATE INDEX CONCURRENTLY IF NOT EXISTS notifications_user_key_prefix_idx
    ON notifications (tenant_id, user_id, key text_pattern_ops)
    WHERE user_id IS NOT NULL;
