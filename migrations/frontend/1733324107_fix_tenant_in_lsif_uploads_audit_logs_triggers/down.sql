CREATE OR REPLACE FUNCTION func_lsif_uploads_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO lsif_uploads_audit_logs
        (upload_id, commit, root, repository_id, uploaded_at,
        indexer, indexer_version, upload_size, associated_index_id,
        content_type,
        operation, transition_columns)
        VALUES (
            NEW.id, NEW.commit, NEW.root, NEW.repository_id, NEW.uploaded_at,
            NEW.indexer, NEW.indexer_version, NEW.upload_size, NEW.associated_index_id,
            NEW.content_type,
            'create', func_lsif_uploads_transition_columns_diff(
                (NULL, NULL, NULL, NULL, NULL, NULL),
                func_row_to_lsif_uploads_transition_columns(NEW)
            )
        );
        RETURN NULL;
    END;
$$;

CREATE OR REPLACE FUNCTION func_lsif_uploads_update() RETURNS trigger
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
            content_type,
            operation, transition_columns)
            VALUES (
                COALESCE(current_setting('codeintel.lsif_uploads_audit.reason', true), ''),
                NEW.id, NEW.commit, NEW.root, NEW.repository_id, NEW.uploaded_at,
                NEW.indexer, NEW.indexer_version, NEW.upload_size, NEW.associated_index_id,
                NEW.content_type,
                'modify', diff
            );
        END IF;

        RETURN NEW;
    END;
$$;

CREATE POLICY tenant_isolation_policy_new ON lsif_uploads_audit_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
DROP POLICY IF EXISTS tenant_isolation_policy ON lsif_uploads_audit_logs;
ALTER POLICY tenant_isolation_policy_new ON lsif_uploads_audit_logs RENAME TO tenant_isolation_policy;
