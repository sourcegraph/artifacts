CREATE TABLE IF NOT EXISTS agent_conversation_sync(
    id serial PRIMARY KEY,
    external_service_id text NOT NULL,
    last_synced_at timestamp with time zone NOT NULL DEFAULT NOW(),
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant') ::integer,
    UNIQUE (external_service_id, tenant_id)
);

ALTER TABLE agent_conversation_sync ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON agent_conversation_sync;

CREATE POLICY tenant_isolation_policy ON agent_conversation_sync AS PERMISSIVE
    FOR ALL TO PUBLIC
        USING (tenant_id =(
            SELECT
                (current_setting('app.current_tenant'::text))::integer AS current_tenant));
