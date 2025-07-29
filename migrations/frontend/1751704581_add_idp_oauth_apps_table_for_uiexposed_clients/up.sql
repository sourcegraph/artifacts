CREATE TABLE IF NOT EXISTS idp_oauth_apps (
    id SERIAL NOT NULL PRIMARY KEY,
    client_id text NOT NULL,
    tenant_id integer NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,
    CONSTRAINT idp_oauth_apps_unique UNIQUE (client_id, tenant_id),
    CONSTRAINT fk_idp_oauth_apps_client_id FOREIGN KEY (client_id, tenant_id) REFERENCES idp_clients(opaque_id, tenant_id) ON DELETE CASCADE
);

ALTER TABLE idp_oauth_apps ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_oauth_apps;
CREATE POLICY tenant_isolation_policy ON idp_oauth_apps AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

-- Backfill existing idp_clients as oauth apps (idempotent)
INSERT INTO idp_oauth_apps (client_id, tenant_id)
SELECT opaque_id, tenant_id
FROM idp_clients
ON CONFLICT (client_id, tenant_id) DO NOTHING;
