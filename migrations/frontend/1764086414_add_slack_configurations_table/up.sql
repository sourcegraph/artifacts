CREATE TABLE IF NOT EXISTS slack_configurations (
    id SERIAL PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    signing_secret text NOT NULL,
    bot_token text NOT NULL,
    encryption_key_id text NOT NULL DEFAULT '',
    created_at timestamp with time zone DEFAULT NOW() NOT NULL,
    updated_at timestamp with time zone DEFAULT NOW() NOT NULL
);

ALTER TABLE slack_configurations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON slack_configurations;
CREATE POLICY tenant_isolation_policy ON slack_configurations AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
