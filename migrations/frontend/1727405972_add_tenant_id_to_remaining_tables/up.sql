CREATE OR REPLACE FUNCTION migrate_add_tenant_id_frontend(table_name text)
RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS tenant_id integer REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;', table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_add_tenant_id_frontend('lsif_configuration_policies'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_configuration_policies_repository_pattern_lookup'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_dependency_indexing_jobs'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_dependency_repos'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_dependency_syncing_jobs'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_dirty_repositories'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_index_configuration'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_indexes'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_last_index_scan'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_last_retention_scan'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_nearest_uploads'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_nearest_uploads_links'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_packages'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_references'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_retention_configuration'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_uploads'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_uploads_audit_logs'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_uploads_reference_counts'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_uploads_visible_at_tip'); COMMIT AND CHAIN;
SELECT migrate_add_tenant_id_frontend('lsif_uploads_vulnerability_scan'); COMMIT AND CHAIN;

DROP FUNCTION migrate_add_tenant_id_frontend(text);
