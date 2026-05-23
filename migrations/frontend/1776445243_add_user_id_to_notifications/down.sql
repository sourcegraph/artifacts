DROP INDEX IF EXISTS notifications_tenant_user_severity_idx;
DROP INDEX IF EXISTS notifications_tenant_user_active_idx;

ALTER TABLE notifications
    DROP COLUMN IF EXISTS user_id;

COMMENT ON TABLE notifications IS 'Persisted admin notifications with deduplication and dismiss/reoccur lifecycle.';
COMMENT ON COLUMN notifications.key IS 'Stable key that uniquely identifies the problem type and context. Used for upsert operations.';
