CREATE OR REPLACE FUNCTION migrate_enable_rls_codeinsights(table_name text)
RETURNS void AS $$
BEGIN
    -- Enable RLS for the table.
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I;', table_name || '_isolation_policy', table_name);
    EXECUTE format('CREATE POLICY %I ON %I AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = current_setting(''app.current_tenant'')::integer);', table_name || '_isolation_policy', table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_enable_rls_codeinsights('insights_data_retention_jobs'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('series_points_snapshots'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('insight_series_recording_times'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('insight_view'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('insight_view_grants'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('archived_insight_series_recording_times'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('archived_series_points'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('dashboard'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('dashboard_grants'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('dashboard_insight_view'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('insight_series'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('insight_series_backfill'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('insight_series_incomplete_points'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('insight_view_series'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('insights_background_jobs'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('metadata'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('repo_iterator'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('repo_iterator_errors'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('repo_names'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeinsights('series_points'); COMMIT AND CHAIN;

DROP FUNCTION migrate_enable_rls_codeinsights(text);
