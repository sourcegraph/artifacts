CREATE OR REPLACE FUNCTION migrate_enable_rls_codeintel(table_name text)
RETURNS void AS $$
BEGIN
    -- Enable RLS for the table.
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I;', table_name || '_isolation_policy', table_name);
    EXECUTE format('CREATE POLICY %I ON %I AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = current_setting(''app.current_tenant'')::integer);', table_name || '_isolation_policy', table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_enable_rls_codeintel('rockskip_repos'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_last_reconcile'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_scip_metadata'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_scip_symbols_schema_versions'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_scip_documents_dereference_logs'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_scip_symbol_names'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('rockskip_ancestry'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_scip_document_lookup_schema_versions'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_scip_document_lookup'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_scip_documents'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('rockskip_symbols'); COMMIT AND CHAIN;
SELECT migrate_enable_rls_codeintel('codeintel_scip_symbols'); COMMIT AND CHAIN;

DROP FUNCTION migrate_enable_rls_codeintel(text);
