CREATE TABLE IF NOT EXISTS metering_events_export_queue (
    id UUID NOT NULL,
    sku INTEGER NOT NULL,
    count INTEGER NOT NULL CHECK (count > 0),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    user_id INTEGER,
    exported_at TIMESTAMP WITH TIME ZONE,
    tenant_id INTEGER NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,
    CONSTRAINT metering_events_export_queue_pkey PRIMARY KEY (tenant_id, id)
);

CREATE INDEX IF NOT EXISTS metering_events_export_queue_created_at_idx
    ON metering_events_export_queue (created_at, id);

CREATE INDEX IF NOT EXISTS metering_events_export_queue_export_order_idx
    ON metering_events_export_queue (created_at, id)
    WHERE exported_at IS NULL;

ALTER TABLE metering_events_export_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON metering_events_export_queue;
CREATE POLICY tenant_isolation_policy ON metering_events_export_queue AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
