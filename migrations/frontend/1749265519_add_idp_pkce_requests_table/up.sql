CREATE TABLE IF NOT EXISTS "idp_pkce_requests" (
    "id" BIGSERIAL NOT NULL PRIMARY KEY,
    "tenant_id" integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    "opaque_id" "text" NOT NULL,
    "client_id" "text" NOT NULL,
    "session_id" bigint NOT NULL,
    "hashed_signature" "text" NOT NULL,
    "requested_at" timestamp with time zone NOT NULL,
    "requested_scopes" text[] NOT NULL,
    "granted_scopes" text[] NOT NULL,
    "requested_audience" text[] NOT NULL,
    "granted_audience" text[] NOT NULL,
    "request_form" "jsonb" NOT NULL,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "deleted_at" timestamp with time zone
);

ALTER TABLE idp_pkce_requests DROP CONSTRAINT IF EXISTS idp_pkce_requests_unique;
ALTER TABLE idp_pkce_requests ADD CONSTRAINT idp_pkce_requests_unique UNIQUE (opaque_id, tenant_id);
CREATE INDEX IF NOT EXISTS "idx_idp_pkce_requests_hashed_signature" ON "idp_pkce_requests" USING "hash" ("hashed_signature");
CREATE INDEX IF NOT EXISTS "idx_idp_pkce_requests_deleted_at" ON "idp_pkce_requests" USING "btree" ("deleted_at");

ALTER TABLE idp_pkce_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_pkce_requests;
CREATE POLICY tenant_isolation_policy ON idp_pkce_requests AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
