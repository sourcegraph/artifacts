-- Rename lsif_uploads and related tables to scip_uploads using COMMIT AND CHAIN to minimize lock duration.
-- See also: https://brandur.org/fragments/postgres-table-rename

-- === Create helper functions ===
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
$func$ LANGUAGE plpgsql;

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
$func$ LANGUAGE plpgsql;

-- Function to rename table, constraints, and create back-compat view
CREATE OR REPLACE FUNCTION rename_table_lsif_to_scip(
    old_table_name TEXT,
    new_table_name TEXT,
    old_indexes TEXT[],
    new_indexes TEXT[],
    old_sequences TEXT[],
    new_sequences TEXT[]
) RETURNS VOID AS $func$
BEGIN
    -- 1. Table rename
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = old_table_name AND table_schema = 'public' AND table_type = 'BASE TABLE') THEN
        EXECUTE format('ALTER TABLE %I RENAME TO %I', old_table_name, new_table_name);
    END IF;

    -- 2. Create back-compat view
    EXECUTE format('CREATE OR REPLACE VIEW %I WITH (security_invoker = true) AS SELECT * FROM %I', old_table_name, new_table_name);

    -- 3. Rename primary key constraint
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = old_table_name || '_pkey') THEN
        EXECUTE format('ALTER TABLE %I RENAME CONSTRAINT %I TO %I', new_table_name, old_table_name || '_pkey', new_table_name || '_pkey');
    END IF;

    -- 4. Rename indexes
    FOR i in 1..COALESCE(array_length(old_indexes, 1), 0) LOOP
        EXECUTE format('ALTER INDEX IF EXISTS %I RENAME TO %I', old_indexes[i], new_indexes[i]);
    END LOOP;

    -- 5. Rename sequences (ownership is preserved automatically)
    FOR i in 1..COALESCE(array_length(old_sequences, 1), 0) LOOP
        IF EXISTS (SELECT 1 FROM pg_sequences WHERE sequencename = old_sequences[i] AND schemaname = 'public') THEN
            EXECUTE format('ALTER SEQUENCE %I RENAME TO %I', old_sequences[i], new_sequences[i]);
        END IF;
    END LOOP;
END;
$func$ LANGUAGE plpgsql;

-- === Table 1: lsif_uploads -> scip_uploads ===
SELECT rename_table_lsif_to_scip('lsif_uploads', 'scip_uploads',
    ARRAY['lsif_uploads_associated_index_id', 'lsif_uploads_commit_last_checked_at', 'lsif_uploads_committed_at', 'lsif_uploads_last_reconcile_at',
          'lsif_uploads_repository_id_commit', 'lsif_uploads_repository_id_indexer', 'lsif_uploads_state', 'lsif_uploads_uploaded_at_id'],
    ARRAY['scip_uploads_associated_index_id', 'scip_uploads_commit_last_checked_at', 'scip_uploads_committed_at', 'scip_uploads_last_reconcile_at',
          'scip_uploads_repository_id_commit', 'scip_uploads_repository_id_indexer', 'scip_uploads_state', 'scip_uploads_uploaded_at_id'],
    ARRAY['lsif_dumps_id_seq'],
    ARRAY['scip_uploads_id_seq']);

-- Rename triggers for lsif_uploads table
SELECT rename_triggers('scip_uploads',
    ARRAY['trigger_lsif_uploads_delete', 'trigger_lsif_uploads_insert', 'trigger_lsif_uploads_update'],
    ARRAY['trigger_scip_uploads_delete', 'trigger_scip_uploads_insert', 'trigger_scip_uploads_update']);

-- Rename functions for lsif_uploads table
SELECT rename_functions(
    ARRAY['func_lsif_uploads_delete', 'func_lsif_uploads_insert', 'func_lsif_uploads_update'],
    ARRAY['func_scip_uploads_delete', 'func_scip_uploads_insert', 'func_scip_uploads_update']);

COMMIT AND CHAIN;

-- === Table 2: lsif_uploads_audit_logs -> scip_uploads_audit_logs ===
SELECT rename_table_lsif_to_scip('lsif_uploads_audit_logs', 'scip_uploads_audit_logs',
    ARRAY['lsif_uploads_audit_logs_timestamp', 'lsif_uploads_audit_logs_upload_id'],
    ARRAY['scip_uploads_audit_logs_timestamp', 'scip_uploads_audit_logs_upload_id'],
    ARRAY['lsif_uploads_audit_logs_seq'],
    ARRAY['scip_uploads_audit_logs_seq']);

COMMIT AND CHAIN;

-- === Table 3: lsif_uploads_reference_counts -> scip_uploads_reference_counts ===
SELECT rename_table_lsif_to_scip('lsif_uploads_reference_counts', 'scip_uploads_reference_counts',
    ARRAY[]::TEXT[],
    ARRAY[]::TEXT[],
    ARRAY[]::TEXT[],
    ARRAY[]::TEXT[]);

COMMIT AND CHAIN;

-- === Table 4: lsif_uploads_visible_at_tip -> scip_uploads_visible_at_tip ===
SELECT rename_table_lsif_to_scip('lsif_uploads_visible_at_tip', 'scip_uploads_visible_at_tip',
    ARRAY['lsif_uploads_visible_at_tip_is_default_branch', 'lsif_uploads_visible_at_tip_repository_id_upload_id'],
    ARRAY['scip_uploads_visible_at_tip_is_default_branch', 'scip_uploads_visible_at_tip_repository_id_upload_id'],
    ARRAY['lsif_uploads_visible_at_tip_id_seq'],
    ARRAY['scip_uploads_visible_at_tip_id_seq']);

COMMIT AND CHAIN;

-- === Table 5: lsif_uploads_vulnerability_scan -> scip_uploads_vulnerability_scan ===
SELECT rename_table_lsif_to_scip('lsif_uploads_vulnerability_scan', 'scip_uploads_vulnerability_scan',
    ARRAY['lsif_uploads_vulnerability_scan_upload_id'],
    ARRAY['scip_uploads_vulnerability_scan_upload_id'],
    ARRAY['lsif_uploads_vulnerability_scan_id_seq'],
    ARRAY['scip_uploads_vulnerability_scan_id_seq']);

COMMIT AND CHAIN;

-- === Table 6: lsif_nearest_uploads -> scip_nearest_uploads ===
SELECT rename_table_lsif_to_scip('lsif_nearest_uploads', 'scip_nearest_uploads',
    ARRAY['lsif_nearest_uploads_repository_id_commit_bytea', 'lsif_nearest_uploads_uploads'],
    ARRAY['scip_nearest_uploads_repository_id_commit_bytea', 'scip_nearest_uploads_uploads'],
    ARRAY['lsif_nearest_uploads_id_seq'],
    ARRAY['scip_nearest_uploads_id_seq']);

COMMIT AND CHAIN;

-- === Table 7: lsif_nearest_uploads_links -> scip_nearest_uploads_links ===
SELECT rename_table_lsif_to_scip('lsif_nearest_uploads_links', 'scip_nearest_uploads_links',
    ARRAY['lsif_nearest_uploads_links_repository_id_ancestor_commit_bytea', 'lsif_nearest_uploads_links_repository_id_commit_bytea'],
    ARRAY['scip_nearest_uploads_links_repository_id_ancestor_commit_bytea', 'scip_nearest_uploads_links_repository_id_commit_bytea'],
    ARRAY['lsif_nearest_uploads_links_id_seq'],
    ARRAY['scip_nearest_uploads_links_id_seq']);

COMMIT AND CHAIN;

-- === Special handling for scip_uploads table ===
-- Rename the special index to have scip_ prefix
ALTER INDEX IF EXISTS lsif_uploads_repository_id_commit_root_indexer RENAME TO scip_uploads_repository_id_commit_root_indexer;

COMMIT AND CHAIN;

-- === Create replacement views over the uploads table ===
-- * lsif_uploads_with_repository_name -> scip_uploads_for_available_repos
-- * lsif_dumps_with_repository_name -> scip_uploads_nav_eligible
-- We will drop the older views in a future major version.

-- Older usages of lsif_uploads_with_repository_name as well as
-- lsif_dumps_with_repository_name made more sense when excluding blocked
-- repos; data related to blocked repos is generally not meant to be
-- accessible (no code search, nav etc.) So the new views below also filter
-- out blocked repos.

CREATE OR REPLACE VIEW scip_uploads_for_available_repos WITH (security_invoker = true) AS
SELECT u.id,
    u.commit,
    u.committed_at,
    u.root,
    u.queued_at,
    u.uploaded_at,
    u.state,
    u.failure_message,
    u.started_at,
    u.finished_at,
    u.repository_id,
    u.indexer,
    u.indexer_version,
    u.num_parts,
    u.uploaded_parts,
    u.process_after,
    u.num_resets,
    u.upload_size,
    u.num_failures,
    u.associated_index_id,
    u.content_type,
    u.should_reindex,
    u.expired,
    u.last_retention_scan_at,
    r.name AS repository_name,
    u.uncompressed_size,
    u.tenant_id
FROM scip_uploads u
JOIN repo r ON r.id = u.repository_id
WHERE r.deleted_at IS NULL
  AND r.blocked IS NULL;
-- N.B. JOIN also excludes repos which have been hard-deleted, but the
-- upload is still lingering (this is possible as there is no FK
-- relationship from scip_uploads.repository_id to repo.id).

CREATE OR REPLACE VIEW scip_uploads_nav_eligible WITH (security_invoker = true) AS
SELECT u.id,
    u.commit,
    u.committed_at,
    u.root,
    u.queued_at,
    u.uploaded_at,
    u.state,
    u.failure_message,
    u.started_at,
    u.finished_at,
    u.repository_id,
    u.indexer,
    u.indexer_version,
    u.num_parts,
    u.uploaded_parts,
    u.process_after,
    u.num_resets,
    u.upload_size,
    u.num_failures,
    u.associated_index_id,
    u.content_type,
    u.should_reindex,
    u.expired,
    u.last_retention_scan_at,
    u.repository_name,
    u.uncompressed_size,
    u.tenant_id
FROM scip_uploads_for_available_repos u
WHERE u.state = 'completed'::text;
-- N.B. JOIN also excludes repos which have been hard-deleted, but the
-- upload is still lingering (this is possible as there is no FK
-- relationship from scip_uploads.repository_id to repo.id).

COMMIT AND CHAIN;

-- === Rename remaining constraints not handled by the general function ===
-- Rename the foreign key constraint that references the renamed table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'lsif_uploads_reference_counts_upload_id_fk') THEN
        ALTER TABLE scip_uploads_reference_counts RENAME CONSTRAINT lsif_uploads_reference_counts_upload_id_fk TO scip_uploads_reference_counts_upload_id_fk;
    END IF;
END
$$;

COMMIT AND CHAIN;

-- === Cleanup ===
-- We can re-add this later if needed; unclear if it is general enough for
-- future rename operations.
DROP FUNCTION rename_table_lsif_to_scip;
DROP FUNCTION rename_triggers;
DROP FUNCTION rename_functions;
