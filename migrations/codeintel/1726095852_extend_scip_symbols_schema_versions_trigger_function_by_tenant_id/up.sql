CREATE OR REPLACE FUNCTION update_codeintel_scip_symbols_schema_versions_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    INSERT INTO codeintel_scip_symbols_schema_versions
    SELECT
        upload_id,
        MIN(schema_version) as min_schema_version,
        MAX(schema_version) as max_schema_version
    FROM newtab
    GROUP BY upload_id
    ON CONFLICT ON CONSTRAINT codeintel_scip_symbols_schema_versions_pkey DO UPDATE SET
        -- Update with min(old_min, new_min) and max(old_max, new_max)
        min_schema_version = LEAST(codeintel_scip_symbols_schema_versions.min_schema_version, EXCLUDED.min_schema_version),
        max_schema_version = GREATEST(codeintel_scip_symbols_schema_versions.max_schema_version, EXCLUDED.max_schema_version);
    RETURN NULL;
END $$;
