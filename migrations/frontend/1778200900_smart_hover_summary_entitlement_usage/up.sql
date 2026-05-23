CREATE TABLE IF NOT EXISTS smart_hover_summary_entitlement_usage (
    user_id           INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entitlement_id    INTEGER NOT NULL REFERENCES entitlements(id) ON DELETE CASCADE,
    consumed          BIGINT NOT NULL DEFAULT 0,
    window_started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tenant_id         INTEGER NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT smart_hover_summary_entitlement_usage_pkey PRIMARY KEY (user_id, entitlement_id)
);

ALTER TABLE smart_hover_summary_entitlement_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON smart_hover_summary_entitlement_usage;
CREATE POLICY tenant_isolation_policy ON smart_hover_summary_entitlement_usage AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS smart_hover_summary_entitlement_usage_user_id_idx ON smart_hover_summary_entitlement_usage(user_id);
CREATE INDEX IF NOT EXISTS smart_hover_summary_entitlement_usage_entitlement_id_idx ON smart_hover_summary_entitlement_usage(entitlement_id);
