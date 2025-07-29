CREATE TABLE IF NOT EXISTS idp_service_account_m2m_clients (
    id SERIAL NOT NULL PRIMARY KEY,
    client_id text NOT NULL,
    service_account_id integer NOT NULL,
    tenant_id integer NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,
    CONSTRAINT idp_service_account_m2m_clients_unique UNIQUE (client_id, tenant_id),
    CONSTRAINT fk_idp_service_account_m2m_clients_client_id FOREIGN KEY (client_id, tenant_id) REFERENCES idp_clients(opaque_id, tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_idp_service_account_m2m_clients_service_account_id FOREIGN KEY (service_account_id) REFERENCES users(id) ON DELETE CASCADE
);

ALTER TABLE idp_service_account_m2m_clients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_service_account_m2m_clients;
CREATE POLICY tenant_isolation_policy ON idp_service_account_m2m_clients AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
