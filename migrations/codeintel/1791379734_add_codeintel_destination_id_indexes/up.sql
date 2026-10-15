-- Cleanup finds garbage documents and essentials by ID, which only manifests
-- list. The tables are written only by the destination writer, which is not
-- enabled yet, so they are empty and the indexes are built at once.
CREATE INDEX IF NOT EXISTS codeintel_documents_tenant_id_id ON codeintel_documents(tenant_id, id);
CREATE INDEX IF NOT EXISTS codeintel_essentials_tenant_id_id ON codeintel_essentials(tenant_id, id);

-- Every cleanup pass looks up the tenant's pending indexes, of which there
-- are few.
CREATE INDEX IF NOT EXISTS codeintel_indexes_pending ON codeintel_indexes(tenant_id) WHERE state = 'pending';
