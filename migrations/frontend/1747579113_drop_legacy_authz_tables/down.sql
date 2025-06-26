-- restore user_permissions

CREATE TABLE IF NOT EXISTS user_permissions (
    user_id integer NOT NULL,
    permission text NOT NULL,
    object_type text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    synced_at timestamp with time zone,
    object_ids_ints integer[] DEFAULT '{}'::integer[] NOT NULL,
    migrated boolean DEFAULT true,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id BIGSERIAL NOT NULL PRIMARY KEY
);

ALTER TABLE ONLY user_permissions DROP CONSTRAINT IF EXISTS user_permissions_perm_object_unique;
ALTER TABLE ONLY user_permissions ADD CONSTRAINT user_permissions_perm_object_unique UNIQUE (user_id, permission, object_type);

DROP POLICY IF EXISTS tenant_isolation_policy ON user_permissions;
CREATE POLICY tenant_isolation_policy ON user_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- restore repo_permissions

CREATE TABLE IF NOT EXISTS repo_permissions (
    repo_id integer NOT NULL,
    permission text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    synced_at timestamp with time zone,
    user_ids_ints integer[] DEFAULT '{}'::integer[] NOT NULL,
    unrestricted boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id BIGSERIAL NOT NULL PRIMARY KEY
);

ALTER TABLE ONLY repo_permissions DROP CONSTRAINT IF EXISTS repo_permissions_perm_unique;
ALTER TABLE ONLY repo_permissions ADD CONSTRAINT repo_permissions_perm_unique UNIQUE (repo_id, permission);

CREATE INDEX IF NOT EXISTS repo_permissions_unrestricted_true_idx ON repo_permissions USING btree (unrestricted) WHERE unrestricted;

DROP POLICY IF EXISTS tenant_isolation_policy ON repo_permissions;
CREATE POLICY tenant_isolation_policy ON repo_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

ALTER TABLE repo_permissions ENABLE ROW LEVEL SECURITY;

-- restore user_pending_permissions

CREATE TABLE IF NOT EXISTS user_pending_permissions (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    bind_id text NOT NULL,
    permission text NOT NULL,
    object_type text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    service_type text NOT NULL,
    service_id text NOT NULL,
    object_ids_ints integer[] DEFAULT '{}'::integer[] NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT user_pending_permissions_service_perm_object_unique UNIQUE (service_type, service_id, permission, object_type, bind_id, tenant_id)
);

DROP POLICY IF EXISTS tenant_isolation_policy ON user_pending_permissions;
CREATE POLICY tenant_isolation_policy ON user_pending_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

ALTER TABLE user_pending_permissions ENABLE ROW LEVEL SECURITY;

-- restore repo_pending_permissions

CREATE TABLE IF NOT EXISTS repo_pending_permissions (
    repo_id integer NOT NULL,
    permission text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    user_ids_ints bigint[] DEFAULT '{}'::integer[] NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id BIGSERIAL NOT NULL PRIMARY KEY,
    CONSTRAINT repo_pending_permissions_perm_unique UNIQUE (repo_id, permission)
);

DROP POLICY IF EXISTS tenant_isolation_policy ON repo_pending_permissions;
CREATE POLICY tenant_isolation_policy ON repo_pending_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

ALTER TABLE repo_pending_permissions ENABLE ROW LEVEL SECURITY;
