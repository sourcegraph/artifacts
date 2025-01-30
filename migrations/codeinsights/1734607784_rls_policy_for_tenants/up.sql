CREATE POLICY tenant_isolation_policy_new ON tenants
  AS PERMISSIVE FOR ALL TO PUBLIC
  USING (
    (SELECT (current_setting('app.current_tenant'::text) IN ('servicetenant'::text, 'workertenant'::text)))
    OR
    (id = (SELECT (NULLIF(NULLIF(current_setting('app.current_tenant'::text), 'servicetenant'::text), 'workertenant'::text))::integer AS current_tenant))
  );
DROP POLICY IF EXISTS tenant_isolation_policy ON tenants;
ALTER POLICY tenant_isolation_policy_new ON tenants RENAME TO tenant_isolation_policy;

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
