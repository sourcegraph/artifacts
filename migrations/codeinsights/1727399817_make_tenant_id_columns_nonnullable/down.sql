CREATE OR REPLACE FUNCTION migrate_tenant_id_non_null_codeinsights_down(table_name text)
RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I DROP COLUMN IF EXISTS tenant_id;', table_name);
    EXECUTE format('ALTER TABLE %I ADD COLUMN tenant_id integer DEFAULT 1 REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;', table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_tenant_id_non_null_codeinsights_down('archived_insight_series_recording_times'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('dashboard'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('dashboard_grants'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('dashboard_insight_view'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insight_series'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insight_series_backfill'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insight_series_incomplete_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insight_view'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insight_view_grants'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insight_view_series'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insights_background_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insights_data_retention_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('insight_series_recording_times'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('metadata'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('repo_iterator'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('repo_iterator_errors'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('repo_names'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('archived_series_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('series_points'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeinsights_down('series_points_snapshots'); COMMIT AND CHAIN;

DROP FUNCTION migrate_tenant_id_non_null_codeinsights_down(text);
