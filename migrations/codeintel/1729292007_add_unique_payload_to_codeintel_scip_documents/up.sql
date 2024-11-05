-- Size of this table on dotcom at the time of writing this migration:
--                    table_name                   |  size   |  tuple_count
-- ------------------------------------------------+---------+---------------
--  codeintel_scip_documents                       | 5057 GB |   646,916,800
-- Expect that this index will take some time to create.
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS codeintel_scip_documents_tnt_id ON codeintel_scip_documents (payload_hash, tenant_id);
