ALTER TABLE notifications
    ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS notifications_tenant_user_active_idx
    ON notifications (tenant_id, user_id, id DESC)
    WHERE dismissed_at IS NULL AND user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS notifications_tenant_user_severity_idx
    ON notifications (tenant_id, user_id, severity)
    WHERE user_id IS NOT NULL;

COMMENT ON TABLE notifications IS 'Persisted admin and user notifications with deduplication and dismiss/reoccur lifecycle.';
COMMENT ON COLUMN notifications.user_id IS 'When set, this notification is scoped to a single user.';
COMMENT ON COLUMN notifications.key IS 'Stable key used for deduplication. When user_id is set, the stored key is namespaced to that user.';
