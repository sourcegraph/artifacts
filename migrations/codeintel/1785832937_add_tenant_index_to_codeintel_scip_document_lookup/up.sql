CREATE INDEX CONCURRENTLY IF NOT EXISTS codeintel_scip_document_lookup_tenant_id
    ON codeintel_scip_document_lookup (tenant_id)
    WHERE tenant_id <> 1;
