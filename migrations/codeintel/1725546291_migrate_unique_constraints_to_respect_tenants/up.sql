DO
$$
BEGIN
    IF to_regclass('codeintel_scip_documents_tnt_id') IS NOT NULL THEN
        ALTER TABLE codeintel_scip_documents DROP CONSTRAINT IF EXISTS codeintel_scip_documents_payload_hash_key;
        ALTER TABLE codeintel_scip_documents ADD CONSTRAINT codeintel_scip_documents_payload_hash_key UNIQUE USING INDEX codeintel_scip_documents_tnt_id;
   END IF;
END
$$;
COMMIT AND CHAIN;

-- This table is tiny, no need to do anything special with concurrent index creation.
ALTER TABLE rockskip_repos ADD CONSTRAINT temp_unique_index UNIQUE(repo,tenant_id);
ALTER TABLE rockskip_repos DROP CONSTRAINT IF EXISTS rockskip_repos_repo_key;
ALTER TABLE rockskip_repos RENAME CONSTRAINT temp_unique_index TO rockskip_repos_repo_key;
