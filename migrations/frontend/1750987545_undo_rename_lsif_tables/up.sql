-- Undo the changes made in the older migration which was reverted:
-- Original PR: https://github.com/sourcegraph/sourcegraph/pull/5861
-- Revert: https://github.com/sourcegraph/sourcegraph/pull/6283

-- However, reverting the PR doesn't undo the DB schema changes on instances
-- where we already migrated, so this patch undoes the change to bring
-- all instances to the same schema.

-- This file is a copy of the down.sql in the original migration PR 5861.

CREATE OR REPLACE FUNCTION rename_triggers(
    table_name TEXT,
    old_trigger_names TEXT[],
    new_trigger_names TEXT[]
) RETURNS VOID AS $func$
BEGIN
    FOR i in 1..COALESCE(array_length(old_trigger_names, 1), 0) LOOP
        IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = old_trigger_names[i]) THEN
            EXECUTE format('ALTER TRIGGER %I ON %I RENAME TO %I', old_trigger_names[i], table_name, new_trigger_names[i]);
        END IF;
    END LOOP;
END;
$func$ LANGUAGE plpgsql; COMMIT AND CHAIN;

CREATE OR REPLACE FUNCTION rename_functions(
    old_function_names TEXT[],
    new_function_names TEXT[]
) RETURNS VOID AS $func$
BEGIN
    FOR i in 1..COALESCE(array_length(old_function_names, 1), 0) LOOP
        IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = old_function_names[i]) THEN
            EXECUTE format('ALTER FUNCTION %I() RENAME TO %I', old_function_names[i], new_function_names[i]);
        END IF;
    END LOOP;
END;
$func$ LANGUAGE plpgsql; COMMIT AND CHAIN;

-- Function to reverse table rename, drop view, and rename constraints back
CREATE OR REPLACE FUNCTION rename_table_scip_to_lsif(
    new_table_name TEXT,
    old_table_name TEXT,
    new_indexes TEXT[],
    old_indexes TEXT[],
    new_sequences TEXT[],
    old_sequences TEXT[]
) RETURNS VOID AS $func$
BEGIN
    -- 1. Rename sequences back (ownership is preserved automatically)
    FOR i in 1..COALESCE(array_length(new_sequences, 1), 0) LOOP
        IF EXISTS (SELECT 1 FROM pg_sequences WHERE sequencename = new_sequences[i] AND schemaname = 'public') THEN
            EXECUTE format('ALTER SEQUENCE %I RENAME TO %I', new_sequences[i], old_sequences[i]);
        END IF;
    END LOOP;

    -- 2. Rename indexes back
    FOR i in 1..COALESCE(array_length(new_indexes, 1), 0) LOOP
        EXECUTE format('ALTER INDEX IF EXISTS %I RENAME TO %I', new_indexes[i], old_indexes[i]);
    END LOOP;

    -- 3. Drop back-compat view
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = old_table_name AND table_schema = 'public') THEN
        EXECUTE format('DROP VIEW %I', old_table_name);
    END IF;

    -- 4. Rename primary key constraint back
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = new_table_name || '_pkey') THEN
        EXECUTE format('ALTER TABLE %I RENAME CONSTRAINT %I TO %I', new_table_name, new_table_name || '_pkey', old_table_name || '_pkey');
    END IF;

    -- 5. Table rename back
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = new_table_name AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        EXECUTE format('ALTER TABLE %I RENAME TO %I', new_table_name, old_table_name);
    END IF;
END;
$func$ LANGUAGE plpgsql; COMMIT AND CHAIN;

-- === Rename remaining constraints not handled by the general function ===
-- Rename the foreign key constraint back to the original name
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'scip_uploads_reference_counts_upload_id_fk') THEN
        ALTER TABLE scip_uploads_reference_counts RENAME CONSTRAINT scip_uploads_reference_counts_upload_id_fk TO lsif_uploads_reference_counts_upload_id_fk;
    END IF;
END $$; COMMIT AND CHAIN;

-- === Drop views (reverse order of creation) ===
DROP VIEW IF EXISTS scip_uploads_nav_eligible; COMMIT AND CHAIN;
DROP VIEW IF EXISTS scip_uploads_for_available_repos; COMMIT AND CHAIN;

-- === Reverse rename tables (reverse order) ===
SELECT rename_table_scip_to_lsif('scip_nearest_uploads_links', 'lsif_nearest_uploads_links',
    ARRAY['scip_nearest_uploads_links_repository_id_ancestor_commit_bytea', 'scip_nearest_uploads_links_repository_id_commit_bytea'],
    ARRAY['lsif_nearest_uploads_links_repository_id_ancestor_commit_bytea', 'lsif_nearest_uploads_links_repository_id_commit_bytea'],
    ARRAY['scip_nearest_uploads_links_id_seq'],
    ARRAY['lsif_nearest_uploads_links_id_seq']); COMMIT AND CHAIN;

SELECT rename_table_scip_to_lsif('scip_nearest_uploads', 'lsif_nearest_uploads',
    ARRAY['scip_nearest_uploads_repository_id_commit_bytea', 'scip_nearest_uploads_uploads'],
    ARRAY['lsif_nearest_uploads_repository_id_commit_bytea', 'lsif_nearest_uploads_uploads'],
    ARRAY['scip_nearest_uploads_id_seq'],
    ARRAY['lsif_nearest_uploads_id_seq']); COMMIT AND CHAIN;

SELECT rename_table_scip_to_lsif('scip_uploads_vulnerability_scan', 'lsif_uploads_vulnerability_scan',
    ARRAY['scip_uploads_vulnerability_scan_upload_id'],
    ARRAY['lsif_uploads_vulnerability_scan_upload_id'],
    ARRAY['scip_uploads_vulnerability_scan_id_seq'],
    ARRAY['lsif_uploads_vulnerability_scan_id_seq']); COMMIT AND CHAIN;

SELECT rename_table_scip_to_lsif('scip_uploads_visible_at_tip', 'lsif_uploads_visible_at_tip',
    ARRAY['scip_uploads_visible_at_tip_is_default_branch', 'scip_uploads_visible_at_tip_repository_id_upload_id'],
    ARRAY['lsif_uploads_visible_at_tip_is_default_branch', 'lsif_uploads_visible_at_tip_repository_id_upload_id'],
    ARRAY['scip_uploads_visible_at_tip_id_seq'],
    ARRAY['lsif_uploads_visible_at_tip_id_seq']); COMMIT AND CHAIN;

SELECT rename_table_scip_to_lsif('scip_uploads_reference_counts', 'lsif_uploads_reference_counts',
    ARRAY[]::TEXT[],
    ARRAY[]::TEXT[],
    ARRAY[]::TEXT[],
    ARRAY[]::TEXT[]); COMMIT AND CHAIN;

SELECT rename_table_scip_to_lsif('scip_uploads_audit_logs', 'lsif_uploads_audit_logs',
    ARRAY['scip_uploads_audit_logs_timestamp', 'scip_uploads_audit_logs_upload_id'],
    ARRAY['lsif_uploads_audit_logs_timestamp', 'lsif_uploads_audit_logs_upload_id'],
    ARRAY['scip_uploads_audit_logs_seq'],
    ARRAY['lsif_uploads_audit_logs_seq']); COMMIT AND CHAIN;

-- Rename functions for scip_uploads table back to lsif_uploads
SELECT rename_functions(
    ARRAY['func_scip_uploads_delete', 'func_scip_uploads_insert', 'func_scip_uploads_update'],
    ARRAY['func_lsif_uploads_delete', 'func_lsif_uploads_insert', 'func_lsif_uploads_update']); COMMIT AND CHAIN;

-- Rename triggers for scip_uploads table back to lsif_uploads
SELECT rename_triggers('scip_uploads',
    ARRAY['trigger_scip_uploads_delete', 'trigger_scip_uploads_insert', 'trigger_scip_uploads_update'],
    ARRAY['trigger_lsif_uploads_delete', 'trigger_lsif_uploads_insert', 'trigger_lsif_uploads_update']); COMMIT AND CHAIN;

-- Use helper function for scip_uploads table (this was done first in up.sql, so should be last here)
SELECT rename_table_scip_to_lsif('scip_uploads', 'lsif_uploads',
    ARRAY['scip_uploads_associated_index_id', 'scip_uploads_commit_last_checked_at', 'scip_uploads_committed_at', 'scip_uploads_last_reconcile_at',
          'scip_uploads_repository_id_commit', 'scip_uploads_repository_id_indexer', 'scip_uploads_state', 'scip_uploads_uploaded_at_id'],
    ARRAY['lsif_uploads_associated_index_id', 'lsif_uploads_commit_last_checked_at', 'lsif_uploads_committed_at', 'lsif_uploads_last_reconcile_at',
          'lsif_uploads_repository_id_commit', 'lsif_uploads_repository_id_indexer', 'lsif_uploads_state', 'lsif_uploads_uploaded_at_id'],
    ARRAY['scip_uploads_id_seq'],
    ARRAY['lsif_dumps_id_seq']); COMMIT AND CHAIN;

-- === Special handling for scip_uploads table ===
DROP INDEX IF EXISTS scip_uploads_repository_id_commit_root_indexer; COMMIT AND CHAIN;
CREATE UNIQUE INDEX IF NOT EXISTS lsif_uploads_repository_id_commit_root_indexer ON lsif_uploads USING btree (repository_id, commit, root, indexer) WHERE (state = 'completed'::text); COMMIT AND CHAIN;

-- Drop the helper functions
DROP FUNCTION rename_table_scip_to_lsif; COMMIT AND CHAIN;
DROP FUNCTION rename_triggers; COMMIT AND CHAIN;
DROP FUNCTION rename_functions;
