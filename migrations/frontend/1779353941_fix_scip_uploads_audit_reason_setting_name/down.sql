-- Revert `func_scip_uploads_update` to read the legacy
-- `codeintel.lsif_uploads_audit.reason` session variable and write into the
-- back-compat view `lsif_uploads_audit_logs` (which forwards to
-- `scip_uploads_audit_logs`).

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
            INSERT INTO lsif_uploads_audit_logs
            (reason, upload_id, commit, root, repository_id, uploaded_at,
            indexer, indexer_version, upload_size, associated_index_id,
            content_type, tenant_id,
            operation, transition_columns)
            VALUES (
                COALESCE(current_setting('codeintel.lsif_uploads_audit.reason', true), ''),
                NEW.id, NEW.commit, NEW.root, NEW.repository_id, NEW.uploaded_at,
                NEW.indexer, NEW.indexer_version, NEW.upload_size, NEW.associated_index_id,
                NEW.content_type, NEW.tenant_id,
                'modify', diff
            );
        END IF;

        RETURN NEW;
    END;
$$;
