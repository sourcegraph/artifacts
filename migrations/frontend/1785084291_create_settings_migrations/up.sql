CREATE TABLE IF NOT EXISTS settings_migrations (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    migration_id INTEGER NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_attempt_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    last_error TEXT,
    last_error_at TIMESTAMP WITH TIME ZONE,
    site_skipped_external BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT settings_migrations_tenant_migration_unique UNIQUE (tenant_id, migration_id)
);

ALTER TABLE settings_migrations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON settings_migrations;
CREATE POLICY tenant_isolation_policy ON settings_migrations AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
