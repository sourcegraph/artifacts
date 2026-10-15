-- Dropping all tables in one transaction can exhaust the default shared lock
-- table, so commit between table groups.
DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('DROP TABLE IF EXISTS codeintel_definition_occurrences_p%s', i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('DROP TABLE IF EXISTS codeintel_reference_occurrences_p%s', i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('DROP TABLE IF EXISTS codeintel_implementation_occurrences_p%s', i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..15 LOOP
        EXECUTE format('DROP TABLE IF EXISTS codeintel_document_payloads_p%1$s, codeintel_essential_symbol_chunks_p%1$s, codeintel_document_path_chunks_p%1$s', i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('DROP TABLE IF EXISTS codeintel_symbols_p%s', i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

-- Dropping a partitioned table also drops its partitions.
DROP TABLE IF EXISTS codeintel_documents, codeintel_essentials;

COMMIT AND CHAIN;

DROP TABLE IF EXISTS
    codeintel_index_package_version_essential_chunks,
    codeintel_index_package_versions,
    codeintel_packages,
    codeintel_index_external_ids,
    codeintel_indexes,
    codeintel_document_manifest_chunks,
    codeintel_document_manifests,
    codeintel_essential_manifest_chunks,
    codeintel_essential_manifests,
    codeintel_writer_control,
    codeintel_scopes,
    codeintel_document_paths;

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..15 LOOP
        EXECUTE format('DROP SEQUENCE IF EXISTS codeintel_document_id_seq_p%1$s, codeintel_essential_id_seq_p%1$s', i);
    END LOOP;
    FOR i IN 0..63 LOOP
        EXECUTE format('DROP SEQUENCE IF EXISTS codeintel_symbol_id_seq_p%s', i);
    END LOOP;
END $$;
