-- We use COMMIT AND CHAIN to avoid holding too many table locks in one
-- transactions.

-- Our migrator expects migrations to be idempotent. However, postgres does
-- not support "IF NOT EXISTS" for ADD CONSTRAINT. So we have to check.
CREATE OR REPLACE FUNCTION migrate_add_constraint_for_unique_indexes_up(tablename text, indexname text)
RETURNS void AS $$
BEGIN
    IF NOT EXISTS (SELECT true
        FROM information_schema.table_constraints
        WHERE constraint_name = indexname
        AND table_name = tablename
    ) THEN
        EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I UNIQUE USING INDEX %I', tablename, indexname, indexname);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT migrate_add_constraint_for_unique_indexes_up('batch_spec_workspace_files', 'batch_spec_workspace_files_batch_spec_id_filename_path');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('cached_available_indexers', 'cached_available_indexers_repository_id');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('codeintel_path_ranks', 'codeintel_path_ranks_graph_key_repository_id');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('codeintel_ranking_exports', 'codeintel_ranking_exports_graph_key_upload_id');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('commit_authors', 'commit_authors_email_name');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('own_aggregate_recent_view', 'own_aggregate_recent_view_viewer');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('package_repo_filters', 'package_repo_filters_unique_matcher_per_scheme');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('repo_paths', 'repo_paths_index_absolute_path');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('sub_repo_permissions', 'sub_repo_permissions_repo_id_user_id_version_uindex');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_up('user_repo_permissions', 'user_repo_permissions_perms_unique_idx');
COMMIT AND CHAIN;

DROP FUNCTION migrate_add_constraint_for_unique_indexes_up(text, text);
