CREATE OR REPLACE FUNCTION migrate_tenant_policy_init_plan_codeintel(table_name text)
RETURNS void AS $$
BEGIN
    EXECUTE format('CREATE POLICY tenant_isolation_policy_new ON %I USING ((tenant_id = (current_setting(''app.current_tenant''::text))::integer));', table_name, table_name);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_policy ON %I', table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I_isolation_policy ON %I', table_name, table_name);
    EXECUTE format('ALTER POLICY tenant_isolation_policy_new ON %I RENAME TO %I_isolation_policy', table_name, table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_last_reconcile'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_scip_document_lookup'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_scip_document_lookup_schema_versions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_scip_documents_dereference_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_scip_documents'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_scip_metadata'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_scip_symbol_names'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_scip_symbols'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('codeintel_scip_symbols_schema_versions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('rockskip_ancestry'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('rockskip_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_codeintel('rockskip_symbols'); COMMIT AND CHAIN;

DROP FUNCTION migrate_tenant_policy_init_plan_codeintel(text);
