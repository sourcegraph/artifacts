CREATE POLICY isolation_policy_2 ON insight_series_backfill USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON insight_series_backfill;
ALTER POLICY isolation_policy_2 ON insight_series_backfill RENAME TO tenant_isolation_policy;
