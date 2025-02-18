CREATE POLICY isolation_policy_2 ON insight_series_backfill USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
DROP POLICY tenant_isolation_policy ON insight_series_backfill;
ALTER POLICY isolation_policy_2 ON insight_series_backfill RENAME TO tenant_isolation_policy;
