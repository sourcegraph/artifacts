CREATE POLICY tenant_isolation_policy_2 ON tenants
    AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
    (SELECT (current_setting('app.current_tenant'::text) IN ('servicetenant'::text, 'workertenant'::text)))
        OR
    (id = (SELECT (NULLIF(NULLIF(current_setting('app.current_tenant'::text), 'servicetenant'::text), 'workertenant'::text))::integer AS current_tenant))
    );
DROP POLICY IF EXISTS tenant_isolation_policy ON tenants;
ALTER POLICY tenant_isolation_policy_2 ON tenants RENAME TO tenant_isolation_policy;
