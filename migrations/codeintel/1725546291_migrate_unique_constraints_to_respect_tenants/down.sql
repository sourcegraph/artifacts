ALTER TABLE codeintel_scip_documents ADD CONSTRAINT temp_unique_index UNIQUE(payload_hash);
ALTER TABLE codeintel_scip_documents DROP CONSTRAINT IF EXISTS codeintel_scip_documents_payload_hash_key;
ALTER TABLE codeintel_scip_documents RENAME CONSTRAINT temp_unique_index TO codeintel_scip_documents_payload_hash_key;
COMMIT AND CHAIN;
CREATE UNIQUE INDEX IF NOT EXISTS codeintel_scip_documents_tnt_id ON codeintel_scip_documents USING btree (payload_hash, tenant_id);
COMMIT AND CHAIN;

ALTER TABLE rockskip_repos ADD CONSTRAINT temp_unique_index UNIQUE(repo);
ALTER TABLE rockskip_repos DROP CONSTRAINT IF EXISTS rockskip_repos_repo_key;
ALTER TABLE rockskip_repos RENAME CONSTRAINT temp_unique_index TO rockskip_repos_repo_key;
