DO $$
BEGIN
    IF to_regclass('public.pending_repo_permissions') IS NULL THEN
        CREATE TABLE pending_repo_permissions (
            id BIGSERIAL PRIMARY KEY,
            bind_id text NOT NULL,
            permission text NOT NULL,
            service_type text NOT NULL,
            service_id text NOT NULL,
            repo_id integer NOT NULL,
            tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant'::text)::integer,
            CONSTRAINT pending_repo_permissions_service_perm_object_unique UNIQUE (permission, service_type, service_id, repo_id, tenant_id, bind_id)
        );

        WITH original_rows AS (
            SELECT
                bind_id,
                permission,
                service_type,
                service_id,
                unnest(object_ids_ints) as object_id,
                tenant_id
            FROM user_pending_permissions
            WHERE
                object_type = 'repos'
        )
        INSERT INTO pending_repo_permissions (
            bind_id,
            permission,
            service_type,
            service_id,
            repo_id,
            tenant_id
        )
        SELECT
            bind_id,
            permission,
            service_type,
            service_id,
            object_id AS repo_id,
            tenant_id
        FROM original_rows
        ON CONFLICT ON CONSTRAINT pending_repo_permissions_service_perm_object_unique DO NOTHING;
    END IF;
END
$$;

ALTER TABLE pending_repo_permissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON pending_repo_permissions;
CREATE POLICY tenant_isolation_policy ON pending_repo_permissions AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
