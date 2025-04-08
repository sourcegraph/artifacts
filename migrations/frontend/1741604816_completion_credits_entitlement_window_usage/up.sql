CREATE TABLE IF NOT EXISTS completion_credits_entitlement_window_usage (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entitlement_id INTEGER NOT NULL REFERENCES entitlements(id) ON DELETE CASCADE,
    usage BIGINT,
    limit_exceeded BOOLEAN,
    last_trail_id BIGINT,
    window_started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (user_id, entitlement_id)
);

-- Enable RLS on both tables
ALTER TABLE completion_credits_entitlement_window_usage ENABLE ROW LEVEL SECURITY;

-- Create tenant isolation policies
DROP POLICY IF EXISTS tenant_isolation_policy ON completion_credits_entitlement_window_usage;
CREATE POLICY tenant_isolation_policy ON completion_credits_entitlement_window_usage AS PERMISSIVE FOR ALL TO PUBLIC
USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
