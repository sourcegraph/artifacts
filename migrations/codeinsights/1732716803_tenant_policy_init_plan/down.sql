CREATE OR REPLACE FUNCTION migrate_tenant_policy_init_plan_codeinsights(table_name text)
RETURNS void AS $$
BEGIN
    EXECUTE format('CREATE POLICY tenant_isolation_policy_new ON %I USING ((tenant_id = (current_setting(''app.current_tenant''::text))::integer));', table_name, table_name);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_policy ON %I', table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I_isolation_policy ON %I', table_name, table_name);
    EXECUTE format('ALTER POLICY tenant_isolation_policy_new ON %I RENAME TO %I_isolation_policy', table_name, table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_tenant_policy_init_plan_codeinsights('archived_insight_series_recording_times'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('archived_series_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('dashboard_grants'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('dashboard_insight_view'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('dashboard'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insight_series_backfill'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insight_series_incomplete_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insight_series'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insight_series_recording_times'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insight_view_grants'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insight_view'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insight_view_series'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insights_background_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('insights_data_retention_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('metadata'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('repo_iterator_errors'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('repo_iterator'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('repo_names'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('series_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeinsights('series_points_snapshots'); COMMIT AND CHAIN;

DROP FUNCTION migrate_tenant_policy_init_plan_codeinsights(text);
