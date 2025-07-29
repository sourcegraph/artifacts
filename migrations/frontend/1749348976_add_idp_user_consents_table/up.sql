CREATE TABLE IF NOT EXISTS idp_user_consents (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT (current_setting('app.current_tenant')::INTEGER),
    user_id INTEGER NOT NULL,
    client_id TEXT NOT NULL,
    scopes TEXT[] NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idp_user_consents_unique_active ON idp_user_consents (tenant_id, user_id, client_id) WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_idp_user_consents_user_client ON idp_user_consents (tenant_id, user_id, client_id);
CREATE INDEX IF NOT EXISTS idx_idp_user_consents_expires_at ON idp_user_consents (expires_at) WHERE expires_at IS NOT NULL;

ALTER TABLE idp_user_consents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_user_consents;
CREATE POLICY tenant_isolation_policy ON idp_user_consents AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE TABLE IF NOT EXISTS idp_consent_requests (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    request_id text NOT NULL,
    client_id text NOT NULL,
    user_id bigint NOT NULL,
    requested_scopes text[] NOT NULL,
    requested_audiences text[] NOT NULL,
    redirect_uri text NOT NULL,
    session_id bigint NOT NULL,
    response_types text[] NOT NULL,
    response_mode text NOT NULL,
    state text,
    request_form jsonb NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    deleted_at timestamp with time zone
);

ALTER TABLE idp_consent_requests DROP CONSTRAINT IF EXISTS idp_consent_requests_unique;
ALTER TABLE idp_consent_requests ADD CONSTRAINT idp_consent_requests_unique UNIQUE (request_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_idp_consent_requests_client_id ON idp_consent_requests USING btree (client_id);
CREATE INDEX IF NOT EXISTS idx_idp_consent_requests_user_id ON idp_consent_requests USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_idp_consent_requests_expires_at ON idp_consent_requests USING btree (expires_at);
CREATE INDEX IF NOT EXISTS idx_idp_consent_requests_deleted_at ON idp_consent_requests USING btree (deleted_at);

ALTER TABLE idp_consent_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_consent_requests;
CREATE POLICY tenant_isolation_policy ON idp_consent_requests AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
