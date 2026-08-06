CREATE TABLE IF NOT EXISTS entitlement_usage_history (
    ID BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entitlement_id INTEGER NOT NULL,
    entitlement_type TEXT NOT NULL,
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    window_end TIMESTAMP WITH TIME ZONE NOT NULL,
    consumed BIGINT NOT NULL,
    total BIGINT NOT NULL,
    telemetry_emitted_at TIMESTAMP WITH TIME ZONE,
    tenant_id INTEGER NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer
);

ALTER TABLE entitlement_usage_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON entitlement_usage_history;
CREATE POLICY tenant_isolation_policy ON entitlement_usage_history AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

ALTER TABLE entitlement_usage_history
    DROP CONSTRAINT IF EXISTS entitlement_usage_history_unique;

ALTER TABLE entitlement_usage_history
    ADD CONSTRAINT entitlement_usage_history_unique
    UNIQUE (user_id, entitlement_type, window_start, window_end, tenant_id);

CREATE INDEX IF NOT EXISTS entitlement_usage_history_telemetry_emitted_at
    ON entitlement_usage_history (telemetry_emitted_at, id);

CREATE INDEX IF NOT EXISTS entitlement_usage_history_export_order_idx
    ON entitlement_usage_history (window_end, id)
    WHERE telemetry_emitted_at IS NULL;

COMMENT ON COLUMN entitlement_usage_history.user_id IS 'ID of the user who consumed the entitlement';
COMMENT ON COLUMN entitlement_usage_history.entitlement_id IS 'ID of the entitlement the usage window referenced (purposefully not a foreign key so it survives deletion)';
COMMENT ON COLUMN entitlement_usage_history.entitlement_type IS 'Type of entitlement (e.g., "deep_search")';
COMMENT ON COLUMN entitlement_usage_history.window_start IS 'Start of the usage window';
COMMENT ON COLUMN entitlement_usage_history.window_end IS 'End of the usage window';
COMMENT ON COLUMN entitlement_usage_history.consumed IS 'Number of units in the entitlement consumed within the window';
COMMENT ON COLUMN entitlement_usage_history.total IS 'Total number of units available to consume within the window';
COMMENT ON COLUMN entitlement_usage_history.telemetry_emitted_at IS 'Timestamp when telemetry was emitted for this usage history entry (or NULL if not emitted)';
