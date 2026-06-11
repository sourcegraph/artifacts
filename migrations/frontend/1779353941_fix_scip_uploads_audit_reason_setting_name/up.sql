-- Fix the audit log trigger so that the `reason` recorded by callers is
-- actually persisted.
--
-- All Go callers in internal/codeintel/uploads/ set the audit reason via
-- `db.SetLocal(ctx, "codeintel.scip_uploads_audit.reason", ...)`, but the
-- trigger function `func_scip_uploads_update` previously read from the
-- legacy `codeintel.lsif_uploads_audit.reason` setting (inherited from when
-- the function was named `func_lsif_uploads_update`). Because the names
-- disagreed, every audit row landed with `reason = ''`.
--
-- This migration aligns the trigger with the Go convention. It also
-- switches the INSERT target from the back-compat view `lsif_uploads_audit_logs`
-- to the real base table `scip_uploads_audit_logs` for clarity. The
-- back-compat view forwards writes to the same table, so this is a no-op
-- on the data path.

CREATE OR REPLACE FUNCTION func_scip_uploads_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        diff hstore[];
    BEGIN
        diff = func_lsif_uploads_transition_columns_diff(
            func_row_to_lsif_uploads_transition_columns(OLD),
            func_row_to_lsif_uploads_transition_columns(NEW)
        );

        IF (array_length(diff, 1) > 0) THEN
            INSERT INTO scip_uploads_audit_logs
            (reason, upload_id, commit, root, repository_id, uploaded_at,
            indexer, indexer_version, upload_size, associated_index_id,
            content_type, tenant_id,
            operation, transition_columns)
            VALUES (
                COALESCE(current_setting('codeintel.scip_uploads_audit.reason', true), ''),
                NEW.id, NEW.commit, NEW.root, NEW.repository_id, NEW.uploaded_at,
                NEW.indexer, NEW.indexer_version, NEW.upload_size, NEW.associated_index_id,
                NEW.content_type, NEW.tenant_id,
                'modify', diff
            );
        END IF;

        RETURN NEW;
    END;
$$;
