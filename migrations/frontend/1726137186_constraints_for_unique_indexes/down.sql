-- postgres drops the underlying index if you remove a constraint, so we have
-- to recreate them.

-- Our migrator expects migrations to be idempotent. However, postgres does
-- not support "IF EXISTS" for DROP CONSTRAINT. So we have to check.
CREATE OR REPLACE FUNCTION migrate_add_constraint_for_unique_indexes_down(tablename text, indexname text, indexcolumns text)
RETURNS void AS $$
BEGIN
    IF EXISTS (SELECT true
        FROM information_schema.table_constraints
        WHERE constraint_name = indexname
        AND table_name = tablename
    ) THEN
        EXECUTE format('CREATE UNIQUE INDEX tmp_unique_index ON %I USING btree (%s);', tablename, indexcolumns);
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I;', tablename, indexname);
        EXECUTE format('ALTER INDEX tmp_unique_index RENAME TO %I;', indexname);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT migrate_add_constraint_for_unique_indexes_down('batch_spec_workspace_files', 'batch_spec_workspace_files_batch_spec_id_filename_path', 'batch_spec_id, filename, path');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('cached_available_indexers', 'cached_available_indexers_repository_id', 'repository_id');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('codeintel_path_ranks', 'codeintel_path_ranks_graph_key_repository_id', 'graph_key, repository_id');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('codeintel_ranking_exports', 'codeintel_ranking_exports_graph_key_upload_id', 'graph_key, upload_id');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('commit_authors', 'commit_authors_email_name', 'email, name');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('own_aggregate_recent_view', 'own_aggregate_recent_view_viewer', 'viewed_file_path_id, viewer_id');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('package_repo_filters', 'package_repo_filters_unique_matcher_per_scheme', 'scheme, matcher');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('repo_paths', 'repo_paths_index_absolute_path', 'repo_id, absolute_path');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('sub_repo_permissions', 'sub_repo_permissions_repo_id_user_id_version_uindex', 'repo_id, user_id, version');
COMMIT AND CHAIN;

SELECT migrate_add_constraint_for_unique_indexes_down('user_repo_permissions', 'user_repo_permissions_perms_unique_idx', 'user_id, user_external_account_id, repo_id');
COMMIT AND CHAIN;

DROP FUNCTION migrate_add_constraint_for_unique_indexes_down(text, text, text);
