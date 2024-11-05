CREATE OR REPLACE FUNCTION migrate_tenant_id_non_null_codeintel_down(table_name text)
RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I DROP COLUMN IF EXISTS tenant_id;', table_name);
    EXECUTE format('ALTER TABLE %I ADD COLUMN tenant_id integer DEFAULT 1 REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;', table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_last_reconcile'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_scip_document_lookup_schema_versions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_scip_metadata'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_scip_symbols_schema_versions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('rockskip_ancestry'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('rockskip_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_scip_document_lookup'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_scip_documents'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_scip_documents_dereference_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_scip_symbol_names'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('codeintel_scip_symbols'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_codeintel_down('rockskip_symbols'); COMMIT AND CHAIN;

DROP FUNCTION migrate_tenant_id_non_null_codeintel_down(text);
