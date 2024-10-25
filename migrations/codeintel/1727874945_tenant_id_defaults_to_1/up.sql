ALTER TABLE codeintel_last_reconcile ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE codeintel_scip_document_lookup ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE codeintel_scip_document_lookup_schema_versions ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE codeintel_scip_documents ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE codeintel_scip_documents_dereference_logs ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE codeintel_scip_metadata ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE codeintel_scip_symbol_names ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE codeintel_scip_symbols ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE codeintel_scip_symbols_schema_versions ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE rockskip_ancestry ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE rockskip_repos ALTER COLUMN tenant_id SET DEFAULT 1; COMMIT AND CHAIN;

ALTER TABLE rockskip_symbols ALTER COLUMN tenant_id SET DEFAULT 1;
