-- Create notifications table for persisted admin notifications
CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,

    -- Unique key: identifies the problem type and context
    -- Examples: 'code_host_token_expired:github:<connection_id>', 'db_unreachable:primary'
    key TEXT NOT NULL,

    -- Classification
    severity TEXT NOT NULL,

    -- Display
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    href TEXT,  -- Optional URL to link to for more details/actions

    -- Lifecycle: dismissed_at is set when user dismisses, cleared on new occurrence
    dismissed_at TIMESTAMP WITH TIME ZONE,
    occurrence_count INTEGER NOT NULL DEFAULT 1,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Unique constraint on key per tenant (prevents duplicate notifications within a tenant)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'notifications_tenant_key_unique'
    ) THEN
        ALTER TABLE notifications
            ADD CONSTRAINT notifications_tenant_key_unique UNIQUE (tenant_id, key);
    END IF;
END
$$;

-- Index for efficient querying of active (non-dismissed) notifications
CREATE INDEX IF NOT EXISTS notifications_tenant_active_idx
    ON notifications (tenant_id) WHERE dismissed_at IS NULL;

-- Index for querying by severity
CREATE INDEX IF NOT EXISTS notifications_tenant_severity_idx
    ON notifications (tenant_id, severity);

-- Enable Row Level Security for tenant isolation
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON notifications;
CREATE POLICY tenant_isolation_policy ON notifications AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

COMMENT ON TABLE notifications IS 'Persisted admin notifications with deduplication and dismiss/reoccur lifecycle.';
COMMENT ON COLUMN notifications.key IS 'Stable key that uniquely identifies the problem type and context. Used for upsert operations.';
COMMENT ON COLUMN notifications.href IS 'Optional URL to link to for more details or actions related to this notification.';
COMMENT ON COLUMN notifications.dismissed_at IS 'When set, notification was dismissed by user. Cleared when a new occurrence happens.';
COMMENT ON COLUMN notifications.occurrence_count IS 'Number of times this notification has been emitted (incremented on re-occurrence after dismiss).';
