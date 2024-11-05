CREATE OR REPLACE FUNCTION migrate_tenant_id_non_null_codeinsights(table_name text)
RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I DROP COLUMN IF EXISTS tenant_id;', table_name);
    EXECUTE format('ALTER TABLE %I ADD COLUMN tenant_id integer NOT NULL DEFAULT 1;', table_name);
    EXECUTE format('ALTER TABLE %I ALTER COLUMN tenant_id SET DEFAULT (current_setting(''app.current_tenant''::text))::integer;', table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_tenant_id_non_null_codeinsights('archived_insight_series_recording_times'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('dashboard'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('dashboard_grants'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('dashboard_insight_view'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insight_series'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insight_series_backfill'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insight_series_incomplete_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insight_view'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insight_view_grants'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insight_view_series'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insights_background_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insights_data_retention_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('insight_series_recording_times'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('metadata'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('repo_iterator'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('repo_iterator_errors'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('repo_names'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('archived_series_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('series_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights('series_points_snapshots'); COMMIT AND CHAIN;

DROP FUNCTION migrate_tenant_id_non_null_codeinsights(text);
