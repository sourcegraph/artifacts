CREATE TABLE IF NOT EXISTS "idp_authorize_codes" (
    "id" BIGSERIAL NOT NULL PRIMARY KEY,
    "tenant_id" integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    "opaque_id" "text" NOT NULL,
    "client_id" "text" NOT NULL,
    "session_id" bigint NOT NULL,
    "active" boolean NOT NULL,
    "hashed_code" "text" NOT NULL,
    "requested_at" timestamp with time zone NOT NULL,
    "requested_scopes" text[] NOT NULL,
    "granted_scopes" text[] NOT NULL,
    "requested_audience" text[] NOT NULL,
    "granted_audience" text[] NOT NULL,
    "request_form" "jsonb" NOT NULL,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now()
);
ALTER TABLE idp_authorize_codes DROP CONSTRAINT IF EXISTS idp_authorize_codes_unique;
ALTER TABLE idp_authorize_codes ADD CONSTRAINT idp_authorize_codes_unique UNIQUE (opaque_id, tenant_id);
CREATE INDEX IF NOT EXISTS "idx_idp_authorize_codes_hashed_code" ON "idp_authorize_codes" USING "hash" ("hashed_code");

CREATE TABLE IF NOT EXISTS "idp_clients" (
    "id" BIGSERIAL NOT NULL PRIMARY KEY,
    "tenant_id" integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    "opaque_id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "hashed_secret" "text" NOT NULL,
    "rotated_hashes" "jsonb" NOT NULL,
    "redirect_uris" text[] NOT NULL,
    "grant_types" text[] NOT NULL,
    "response_types" text[] NOT NULL,
    "scopes" text[] NOT NULL,
    "public" boolean NOT NULL,
    "audience" text[] NOT NULL,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "deleted_at" timestamp with time zone
);
ALTER TABLE idp_clients DROP CONSTRAINT IF EXISTS idp_clients_unique;
ALTER TABLE idp_clients ADD CONSTRAINT idp_clients_unique UNIQUE (opaque_id, tenant_id);
CREATE INDEX IF NOT EXISTS "idx_idp_clients_deleted_at" ON "idp_clients" USING "btree" ("deleted_at");

CREATE TABLE IF NOT EXISTS "idp_id_tokens" (
    "id" BIGSERIAL NOT NULL PRIMARY KEY,
    "tenant_id" integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    "opaque_id" "text" NOT NULL,
    "client_id" "text" NOT NULL,
    "session_id" bigint NOT NULL,
    "hashed_authorize_code" "text" NOT NULL,
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
ALTER TABLE idp_id_tokens DROP CONSTRAINT IF EXISTS idp_id_tokens_unique;
ALTER TABLE idp_id_tokens ADD CONSTRAINT idp_id_tokens_unique UNIQUE (opaque_id, tenant_id);
CREATE INDEX IF NOT EXISTS "idx_idp_id_tokens_deleted_at" ON "idp_id_tokens" USING "btree" ("deleted_at");
CREATE INDEX IF NOT EXISTS "idx_idp_id_tokens_hashed_authorize_code" ON "idp_id_tokens" USING "hash" ("hashed_authorize_code");

CREATE TABLE IF NOT EXISTS "idp_sessions" (
    "id" BIGSERIAL NOT NULL PRIMARY KEY,
    "tenant_id" integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    "client_id" "text" NOT NULL,
    "claims" "jsonb" NOT NULL,
    "headers" "jsonb" NOT NULL,
    "expires_at" "jsonb" NOT NULL,
    "created_at" timestamp with time zone NOT NULL DEFAULT now(),
    "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
    "deleted_at" timestamp with time zone
);
ALTER TABLE idp_sessions DROP CONSTRAINT IF EXISTS idp_sessions_unique;
ALTER TABLE idp_sessions ADD CONSTRAINT idp_sessions_unique UNIQUE (id, tenant_id);
CREATE INDEX IF NOT EXISTS "idx_idp_sessions_deleted_at" ON "idp_sessions" USING "btree" ("deleted_at");

CREATE TABLE IF NOT EXISTS "idp_tokens" (
    "id" BIGSERIAL NOT NULL PRIMARY KEY,
    "tenant_id" integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    "opaque_id" "text" NOT NULL,
    "type" "text" NOT NULL,
    "client_id" "text" NOT NULL,
    "session_id" bigint NOT NULL,
    "active" boolean NOT NULL,
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
ALTER TABLE idp_tokens DROP CONSTRAINT IF EXISTS idp_tokens_unique;
ALTER TABLE idp_tokens ADD CONSTRAINT idp_tokens_unique UNIQUE (opaque_id, type, tenant_id);
CREATE INDEX IF NOT EXISTS "idx_idp_tokens_deleted_at" ON "idp_tokens" USING "btree" ("deleted_at");
CREATE INDEX IF NOT EXISTS "idx_idp_tokens_hashed_signature" ON "idp_tokens" USING "hash" ("hashed_signature");

ALTER TABLE idp_authorize_codes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_authorize_codes;
CREATE POLICY tenant_isolation_policy ON idp_authorize_codes AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

ALTER TABLE idp_clients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_clients;
CREATE POLICY tenant_isolation_policy ON idp_clients AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

ALTER TABLE idp_id_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_id_tokens;
CREATE POLICY tenant_isolation_policy ON idp_id_tokens AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

ALTER TABLE idp_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_sessions;
CREATE POLICY tenant_isolation_policy ON idp_sessions AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

ALTER TABLE idp_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON idp_tokens;
CREATE POLICY tenant_isolation_policy ON idp_tokens AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
