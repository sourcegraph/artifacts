CREATE TABLE IF NOT EXISTS "idp_device_auth_requests" (
    "id" BIGSERIAL NOT NULL PRIMARY KEY,
    "tenant_id" integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    "opaque_id" "text" NOT NULL,
    "client_id" "text" NOT NULL,
    "session_id" bigint NOT NULL,
    "hashed_device_code_signature" "text" NOT NULL,
    "hashed_user_code_signature" "text" NOT NULL,
    "active" boolean NOT NULL DEFAULT true,
    "user_code_state" smallint NOT NULL DEFAULT 0,
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

ALTER TABLE idp_device_auth_requests DROP CONSTRAINT IF EXISTS idp_device_auth_requests_unique;
ALTER TABLE idp_device_auth_requests ADD CONSTRAINT idp_device_auth_requests_unique UNIQUE (opaque_id, tenant_id);
CREATE INDEX IF NOT EXISTS "idx_idp_device_auth_requests_hashed_device_code_signature" ON "idp_device_auth_requests" USING "hash" ("hashed_device_code_signature");
CREATE INDEX IF NOT EXISTS "idx_idp_device_auth_requests_hashed_user_code_signature" ON "idp_device_auth_requests" USING "hash" ("hashed_user_code_signature");
CREATE INDEX IF NOT EXISTS "idx_idp_device_auth_requests_deleted_at" ON "idp_device_auth_requests" USING "btree" ("deleted_at");

ALTER TABLE idp_device_auth_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_device_auth_requests;
CREATE POLICY tenant_isolation_policy ON idp_device_auth_requests AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

-- Add unique constraint for user code signature scoped by tenant to prevent collisions
-- This ensures that each user code signature is unique within a tenant, which is required
-- for the OAuth 2.0 Device Authorization Grant (RFC 8628) to work correctly.
ALTER TABLE idp_device_auth_requests DROP CONSTRAINT IF EXISTS idp_device_auth_requests_user_code_signature_unique;
ALTER TABLE idp_device_auth_requests
ADD CONSTRAINT idp_device_auth_requests_user_code_signature_unique
UNIQUE (hashed_user_code_signature, tenant_id);

ALTER TABLE idp_device_auth_requests DROP CONSTRAINT IF EXISTS idp_device_auth_requests_device_code_signature_unique;
ALTER TABLE idp_device_auth_requests
ADD CONSTRAINT idp_device_auth_requests_device_code_signature_unique
UNIQUE (hashed_device_code_signature, tenant_id);
