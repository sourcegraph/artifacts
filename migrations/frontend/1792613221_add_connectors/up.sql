CREATE TABLE IF NOT EXISTS connectors (
    id SERIAL PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    -- The user who owns a personal connector, which only their agents can use.
    -- NULL for connectors that administrators configured for all users.
    owner_user_id integer REFERENCES users(id) ON DELETE CASCADE,
    name text NOT NULL,
    slug text NOT NULL,
    url text NOT NULL,
    auth_type text NOT NULL,
    -- Non-secret OAuth settings discovered from the server (endpoints, scopes, client ID).
    oauth_metadata jsonb,
    -- Encrypted JSON with the bearer token or OAuth client secret.
    encrypted_credentials text NOT NULL DEFAULT '',
    encryption_key_id text NOT NULL DEFAULT '',
    -- Data URL of the server's icon, so browsers don't request it from the server.
    icon text NOT NULL DEFAULT '',
    -- The instructions the MCP server gives about using its tools.
    instructions text NOT NULL DEFAULT '',
    -- Last successfully listed tools of the MCP server.
    tools jsonb NOT NULL DEFAULT '[]'::jsonb,
    tools_updated_at timestamp with time zone,
    -- The error of the last failed attempt to list the tools, which is cleared
    -- by the next successful one.
    tools_refresh_error text,
    tools_refresh_failed_at timestamp with time zone,
    -- Set when the server rejected the shared credentials, until the
    -- connector is updated or the server accepts them again.
    credentials_rejected_at timestamp with time zone,
    disabled_tools text[] NOT NULL DEFAULT '{}'::text[],
    created_at timestamp with time zone NOT NULL DEFAULT NOW(),
    updated_at timestamp with time zone NOT NULL DEFAULT NOW()
);
-- Slugs are unique among the connectors administrators configured, and among
-- each user's personal connectors.
CREATE UNIQUE INDEX IF NOT EXISTS connectors_unique_tenant_slug ON connectors (tenant_id, slug) WHERE owner_user_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS connectors_unique_tenant_owner_slug ON connectors (tenant_id, owner_user_id, slug) WHERE owner_user_id IS NOT NULL;

ALTER TABLE connectors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON connectors;
CREATE POLICY tenant_isolation_policy ON connectors AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE TABLE IF NOT EXISTS connector_user_tokens (
    id SERIAL PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    connector_id integer NOT NULL REFERENCES connectors(id) ON DELETE CASCADE,
    user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- Encrypted JSON with the user's OAuth access and refresh tokens.
    encrypted_token text NOT NULL,
    encryption_key_id text NOT NULL DEFAULT '',
    -- Set when the token stopped working, so the user has to connect again.
    expired_at timestamp with time zone,
    -- When refreshing the current token first failed with a revoked refresh
    -- token, see internal/oauthtoken.
    refresh_failure_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT NOW(),
    updated_at timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT connector_user_tokens_unique_tenant_connector_user UNIQUE (tenant_id, connector_id, user_id)
);
CREATE INDEX IF NOT EXISTS connector_user_tokens_user_id ON connector_user_tokens (user_id);

ALTER TABLE connector_user_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON connector_user_tokens;
CREATE POLICY tenant_isolation_policy ON connector_user_tokens AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

-- Per-user settings of connectors, such as turning a connector off for the
-- user's agents.
CREATE TABLE IF NOT EXISTS connector_user_settings (
    id SERIAL PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    connector_id integer NOT NULL REFERENCES connectors(id) ON DELETE CASCADE,
    user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    batch_change_agent_disabled boolean NOT NULL DEFAULT false,
    batch_change_coding_agent_disabled boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT NOW(),
    updated_at timestamp with time zone NOT NULL DEFAULT NOW(),
    CONSTRAINT connector_user_settings_unique_tenant_connector_user UNIQUE (tenant_id, connector_id, user_id)
);

ALTER TABLE connector_user_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON connector_user_settings;
CREATE POLICY tenant_isolation_policy ON connector_user_settings AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
