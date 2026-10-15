CREATE EXTENSION IF NOT EXISTS intarray;

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';

DO $$
BEGIN
	CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
	COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';
EXCEPTION
	WHEN OTHERS THEN
		RAISE NOTICE 'Failed to install optional extension, skipping: pg_stat_statements: %', SQLERRM;
END
$$;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';

CREATE TYPE tenant_state AS ENUM (
    'active',
    'suspended',
    'dormant',
    'deleted'
);

CREATE FUNCTION get_file_extension(path text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$ BEGIN
    RETURN substring(path FROM '\.([^\.]*)$');
END; $_$;

CREATE FUNCTION path_prefixes(path text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$ BEGIN
    RETURN (
        SELECT array_agg(array_to_string(components[:len], '/')) prefixes
        FROM
            (SELECT regexp_split_to_array(path, E'/') components) t,
            generate_series(1, array_length(components, 1)) AS len
    );
END; $$;

CREATE FUNCTION singleton(value text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$ BEGIN
    RETURN ARRAY[value];
END; $$;

CREATE FUNCTION singleton_integer(value integer) RETURNS integer[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$ BEGIN
    RETURN ARRAY[value];
END; $$;

CREATE FUNCTION update_codeintel_scip_document_lookup_schema_versions_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    INSERT INTO codeintel_scip_document_lookup_schema_versions
    SELECT
        upload_id,
        MIN(schema_version) as min_schema_version,
        MAX(schema_version) as max_schema_version
    FROM newtab
    JOIN codeintel_scip_documents ON codeintel_scip_documents.id = newtab.document_id
    GROUP BY newtab.upload_id
    ON CONFLICT ON CONSTRAINT codeintel_scip_document_lookup_schema_versions_pkey DO UPDATE SET
        -- Update with min(old_min, new_min) and max(old_max, new_max)
        min_schema_version = LEAST(codeintel_scip_document_lookup_schema_versions.min_schema_version, EXCLUDED.min_schema_version),
        max_schema_version = GREATEST(codeintel_scip_document_lookup_schema_versions.max_schema_version, EXCLUDED.max_schema_version);
    RETURN NULL;
END $$;

CREATE FUNCTION update_codeintel_scip_documents_dereference_logs_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    INSERT INTO codeintel_scip_documents_dereference_logs (document_id)
    SELECT document_id FROM oldtab;
    RETURN NULL;
END $$;

CREATE FUNCTION update_codeintel_scip_symbols_schema_versions_insert() RETURNS trigger
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

CREATE TABLE codeintel_definition_occurrences_p0 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p0_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p0_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 0)),
    CONSTRAINT codeintel_definition_occurrences_p0_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p0 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p1 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p1_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p1_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 1)),
    CONSTRAINT codeintel_definition_occurrences_p1_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p1 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p10 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p10_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p10_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 10)),
    CONSTRAINT codeintel_definition_occurrences_p10_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p10 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p11 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p11_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p11_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 11)),
    CONSTRAINT codeintel_definition_occurrences_p11_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p11 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p12 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p12_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p12_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 12)),
    CONSTRAINT codeintel_definition_occurrences_p12_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p12 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p13 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p13_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p13_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 13)),
    CONSTRAINT codeintel_definition_occurrences_p13_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p13 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p14 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p14_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p14_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 14)),
    CONSTRAINT codeintel_definition_occurrences_p14_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p14 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p15 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p15_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p15_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 15)),
    CONSTRAINT codeintel_definition_occurrences_p15_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p15 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p16 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p16_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p16_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 16)),
    CONSTRAINT codeintel_definition_occurrences_p16_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p16 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p17 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p17_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p17_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 17)),
    CONSTRAINT codeintel_definition_occurrences_p17_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p17 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p18 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p18_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p18_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 18)),
    CONSTRAINT codeintel_definition_occurrences_p18_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p18 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p19 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p19_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p19_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 19)),
    CONSTRAINT codeintel_definition_occurrences_p19_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p19 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p2 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p2_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p2_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 2)),
    CONSTRAINT codeintel_definition_occurrences_p2_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p2 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p20 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p20_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p20_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 20)),
    CONSTRAINT codeintel_definition_occurrences_p20_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p20 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p21 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p21_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p21_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 21)),
    CONSTRAINT codeintel_definition_occurrences_p21_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p21 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p22 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p22_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p22_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 22)),
    CONSTRAINT codeintel_definition_occurrences_p22_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p22 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p23 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p23_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p23_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 23)),
    CONSTRAINT codeintel_definition_occurrences_p23_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p23 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p24 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p24_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p24_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 24)),
    CONSTRAINT codeintel_definition_occurrences_p24_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p24 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p25 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p25_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p25_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 25)),
    CONSTRAINT codeintel_definition_occurrences_p25_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p25 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p26 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p26_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p26_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 26)),
    CONSTRAINT codeintel_definition_occurrences_p26_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p26 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p27 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p27_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p27_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 27)),
    CONSTRAINT codeintel_definition_occurrences_p27_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p27 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p28 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p28_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p28_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 28)),
    CONSTRAINT codeintel_definition_occurrences_p28_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p28 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p29 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p29_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p29_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 29)),
    CONSTRAINT codeintel_definition_occurrences_p29_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p29 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p3 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p3_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p3_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 3)),
    CONSTRAINT codeintel_definition_occurrences_p3_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p3 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p30 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p30_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p30_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 30)),
    CONSTRAINT codeintel_definition_occurrences_p30_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p30 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p31 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p31_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p31_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 31)),
    CONSTRAINT codeintel_definition_occurrences_p31_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p31 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p32 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p32_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p32_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 32)),
    CONSTRAINT codeintel_definition_occurrences_p32_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p32 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p33 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p33_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p33_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 33)),
    CONSTRAINT codeintel_definition_occurrences_p33_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p33 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p34 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p34_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p34_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 34)),
    CONSTRAINT codeintel_definition_occurrences_p34_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p34 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p35 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p35_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p35_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 35)),
    CONSTRAINT codeintel_definition_occurrences_p35_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p35 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p36 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p36_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p36_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 36)),
    CONSTRAINT codeintel_definition_occurrences_p36_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p36 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p37 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p37_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p37_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 37)),
    CONSTRAINT codeintel_definition_occurrences_p37_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p37 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p38 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p38_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p38_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 38)),
    CONSTRAINT codeintel_definition_occurrences_p38_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p38 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p39 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p39_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p39_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 39)),
    CONSTRAINT codeintel_definition_occurrences_p39_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p39 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p4 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p4_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p4_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 4)),
    CONSTRAINT codeintel_definition_occurrences_p4_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p4 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p40 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p40_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p40_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 40)),
    CONSTRAINT codeintel_definition_occurrences_p40_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p40 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p41 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p41_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p41_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 41)),
    CONSTRAINT codeintel_definition_occurrences_p41_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p41 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p42 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p42_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p42_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 42)),
    CONSTRAINT codeintel_definition_occurrences_p42_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p42 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p43 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p43_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p43_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 43)),
    CONSTRAINT codeintel_definition_occurrences_p43_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p43 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p44 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p44_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p44_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 44)),
    CONSTRAINT codeintel_definition_occurrences_p44_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p44 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p45 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p45_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p45_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 45)),
    CONSTRAINT codeintel_definition_occurrences_p45_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p45 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p46 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p46_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p46_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 46)),
    CONSTRAINT codeintel_definition_occurrences_p46_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p46 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p47 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p47_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p47_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 47)),
    CONSTRAINT codeintel_definition_occurrences_p47_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p47 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p48 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p48_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p48_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 48)),
    CONSTRAINT codeintel_definition_occurrences_p48_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p48 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p49 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p49_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p49_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 49)),
    CONSTRAINT codeintel_definition_occurrences_p49_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p49 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p5 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p5_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p5_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 5)),
    CONSTRAINT codeintel_definition_occurrences_p5_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p5 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p50 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p50_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p50_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 50)),
    CONSTRAINT codeintel_definition_occurrences_p50_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p50 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p51 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p51_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p51_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 51)),
    CONSTRAINT codeintel_definition_occurrences_p51_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p51 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p52 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p52_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p52_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 52)),
    CONSTRAINT codeintel_definition_occurrences_p52_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p52 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p53 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p53_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p53_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 53)),
    CONSTRAINT codeintel_definition_occurrences_p53_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p53 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p54 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p54_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p54_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 54)),
    CONSTRAINT codeintel_definition_occurrences_p54_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p54 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p55 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p55_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p55_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 55)),
    CONSTRAINT codeintel_definition_occurrences_p55_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p55 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p56 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p56_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p56_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 56)),
    CONSTRAINT codeintel_definition_occurrences_p56_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p56 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p57 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p57_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p57_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 57)),
    CONSTRAINT codeintel_definition_occurrences_p57_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p57 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p58 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p58_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p58_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 58)),
    CONSTRAINT codeintel_definition_occurrences_p58_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p58 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p59 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p59_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p59_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 59)),
    CONSTRAINT codeintel_definition_occurrences_p59_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p59 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p6 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p6_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p6_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 6)),
    CONSTRAINT codeintel_definition_occurrences_p6_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p6 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p60 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p60_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p60_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 60)),
    CONSTRAINT codeintel_definition_occurrences_p60_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p60 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p61 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p61_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p61_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 61)),
    CONSTRAINT codeintel_definition_occurrences_p61_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p61 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p62 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p62_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p62_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 62)),
    CONSTRAINT codeintel_definition_occurrences_p62_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p62 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p63 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p63_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p63_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 63)),
    CONSTRAINT codeintel_definition_occurrences_p63_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p63 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p7 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p7_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p7_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 7)),
    CONSTRAINT codeintel_definition_occurrences_p7_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p7 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p8 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p8_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p8_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 8)),
    CONSTRAINT codeintel_definition_occurrences_p8_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p8 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_definition_occurrences_p9 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_definition_occurrences_p9_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_definition_occurrences_p9_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 9)),
    CONSTRAINT codeintel_definition_occurrences_p9_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_definition_occurrences_p9 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE SEQUENCE codeintel_document_id_seq_p0
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p1
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p10
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p11
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p12
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p13
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p14
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p15
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p2
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p3
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p4
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p5
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p6
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p7
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p8
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_document_id_seq_p9
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE TABLE codeintel_document_manifest_chunks (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    document_manifest_id bigint NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_manifest_chunks_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_manifest_chunks_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_manifest_chunks ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_manifests (
    id bigint NOT NULL,
    essential_manifest_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    document_count integer NOT NULL,
    hash bytea NOT NULL,
    CONSTRAINT codeintel_document_manifests_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_document_manifests_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE SEQUENCE codeintel_document_manifests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_document_manifests_id_seq OWNED BY codeintel_document_manifests.id;

CREATE TABLE codeintel_document_path_chunks_p0 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p0_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p0_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p0 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p1 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p1_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p1_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p1 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p10 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p10_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p10_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p10 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p11 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p11_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p11_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p11 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p12 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p12_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p12_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p12 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p13 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p13_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p13_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p13 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p14 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p14_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p14_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p14 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p15 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p15_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p15_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p15 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p2 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p2_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p2_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p2 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p3 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p3_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p3_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p3 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p4 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p4_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p4_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p4 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p5 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p5_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p5_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p5 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p6 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p6_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p6_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p6 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p7 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p7_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p7_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p7 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p8 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p8_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p8_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p8 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_path_chunks_p9 (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scope_id integer NOT NULL,
    bucket integer NOT NULL,
    order_key bytea NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_document_path_chunks_p9_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_document_path_chunks_p9_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_path_chunks_p9 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_paths (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    relative_path text NOT NULL COLLATE pg_catalog."C",
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_document_paths_order_key_check CHECK (((octet_length(order_key) >= 1) AND (octet_length(order_key) <= 1024))),
    CONSTRAINT codeintel_document_paths_tenant_id_check CHECK ((tenant_id > 0))
)
WITH (fillfactor='70');

CREATE TABLE codeintel_document_payloads_p0 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p0_document_id_check CHECK (((document_id % (16)::bigint) = 0)),
    CONSTRAINT codeintel_document_payloads_p0_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p0 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p1 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p1_document_id_check CHECK (((document_id % (16)::bigint) = 1)),
    CONSTRAINT codeintel_document_payloads_p1_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p1 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p10 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p10_document_id_check CHECK (((document_id % (16)::bigint) = 10)),
    CONSTRAINT codeintel_document_payloads_p10_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p10 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p11 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p11_document_id_check CHECK (((document_id % (16)::bigint) = 11)),
    CONSTRAINT codeintel_document_payloads_p11_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p11 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p12 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p12_document_id_check CHECK (((document_id % (16)::bigint) = 12)),
    CONSTRAINT codeintel_document_payloads_p12_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p12 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p13 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p13_document_id_check CHECK (((document_id % (16)::bigint) = 13)),
    CONSTRAINT codeintel_document_payloads_p13_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p13 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p14 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p14_document_id_check CHECK (((document_id % (16)::bigint) = 14)),
    CONSTRAINT codeintel_document_payloads_p14_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p14 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p15 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p15_document_id_check CHECK (((document_id % (16)::bigint) = 15)),
    CONSTRAINT codeintel_document_payloads_p15_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p15 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p2 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p2_document_id_check CHECK (((document_id % (16)::bigint) = 2)),
    CONSTRAINT codeintel_document_payloads_p2_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p2 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p3 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p3_document_id_check CHECK (((document_id % (16)::bigint) = 3)),
    CONSTRAINT codeintel_document_payloads_p3_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p3 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p4 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p4_document_id_check CHECK (((document_id % (16)::bigint) = 4)),
    CONSTRAINT codeintel_document_payloads_p4_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p4 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p5 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p5_document_id_check CHECK (((document_id % (16)::bigint) = 5)),
    CONSTRAINT codeintel_document_payloads_p5_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p5 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p6 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p6_document_id_check CHECK (((document_id % (16)::bigint) = 6)),
    CONSTRAINT codeintel_document_payloads_p6_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p6 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p7 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p7_document_id_check CHECK (((document_id % (16)::bigint) = 7)),
    CONSTRAINT codeintel_document_payloads_p7_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p7 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p8 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p8_document_id_check CHECK (((document_id % (16)::bigint) = 8)),
    CONSTRAINT codeintel_document_payloads_p8_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p8 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_document_payloads_p9 (
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    payload bytea NOT NULL,
    CONSTRAINT codeintel_document_payloads_p9_document_id_check CHECK (((document_id % (16)::bigint) = 9)),
    CONSTRAINT codeintel_document_payloads_p9_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_document_payloads_p9 ALTER COLUMN payload SET STORAGE EXTERNAL;

CREATE TABLE codeintel_documents (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
)
PARTITION BY RANGE (hash);

CREATE TABLE codeintel_documents_p0 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p1 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p10 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p11 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p12 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p13 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p14 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p15 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p2 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p3 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p4 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p5 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p6 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p7 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p8 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_documents_p9 (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_documents_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_documents_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE SEQUENCE codeintel_essential_id_seq_p0
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p1
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p10
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p11
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p12
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p13
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p14
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p15
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p2
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p3
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p4
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p5
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p6
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p7
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p8
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE SEQUENCE codeintel_essential_id_seq_p9
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 576460752303423487
    CACHE 1;

CREATE TABLE codeintel_essential_manifest_chunks (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_manifest_id bigint NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_manifest_chunks_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_manifest_chunks_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_manifest_chunks ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_manifests (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_count integer NOT NULL,
    scope_id integer NOT NULL,
    hash bytea NOT NULL,
    CONSTRAINT codeintel_essential_manifests_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essential_manifests_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE SEQUENCE codeintel_essential_manifests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_essential_manifests_id_seq OWNED BY codeintel_essential_manifests.id;

CREATE TABLE codeintel_essential_symbol_chunks_p0 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p0_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p0_essential_id_check CHECK (((essential_id % (16)::bigint) = 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p0_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p0 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p1 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p1_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p1_essential_id_check CHECK (((essential_id % (16)::bigint) = 1)),
    CONSTRAINT codeintel_essential_symbol_chunks_p1_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p1 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p10 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p10_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p10_essential_id_check CHECK (((essential_id % (16)::bigint) = 10)),
    CONSTRAINT codeintel_essential_symbol_chunks_p10_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p10 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p11 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p11_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p11_essential_id_check CHECK (((essential_id % (16)::bigint) = 11)),
    CONSTRAINT codeintel_essential_symbol_chunks_p11_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p11 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p12 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p12_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p12_essential_id_check CHECK (((essential_id % (16)::bigint) = 12)),
    CONSTRAINT codeintel_essential_symbol_chunks_p12_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p12 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p13 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p13_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p13_essential_id_check CHECK (((essential_id % (16)::bigint) = 13)),
    CONSTRAINT codeintel_essential_symbol_chunks_p13_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p13 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p14 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p14_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p14_essential_id_check CHECK (((essential_id % (16)::bigint) = 14)),
    CONSTRAINT codeintel_essential_symbol_chunks_p14_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p14 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p15 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p15_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p15_essential_id_check CHECK (((essential_id % (16)::bigint) = 15)),
    CONSTRAINT codeintel_essential_symbol_chunks_p15_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p15 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p2 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p2_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p2_essential_id_check CHECK (((essential_id % (16)::bigint) = 2)),
    CONSTRAINT codeintel_essential_symbol_chunks_p2_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p2 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p3 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p3_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p3_essential_id_check CHECK (((essential_id % (16)::bigint) = 3)),
    CONSTRAINT codeintel_essential_symbol_chunks_p3_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p3 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p4 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p4_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p4_essential_id_check CHECK (((essential_id % (16)::bigint) = 4)),
    CONSTRAINT codeintel_essential_symbol_chunks_p4_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p4 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p5 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p5_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p5_essential_id_check CHECK (((essential_id % (16)::bigint) = 5)),
    CONSTRAINT codeintel_essential_symbol_chunks_p5_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p5 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p6 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p6_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p6_essential_id_check CHECK (((essential_id % (16)::bigint) = 6)),
    CONSTRAINT codeintel_essential_symbol_chunks_p6_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p6 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p7 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p7_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p7_essential_id_check CHECK (((essential_id % (16)::bigint) = 7)),
    CONSTRAINT codeintel_essential_symbol_chunks_p7_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p7 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p8 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p8_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p8_essential_id_check CHECK (((essential_id % (16)::bigint) = 8)),
    CONSTRAINT codeintel_essential_symbol_chunks_p8_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p8 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essential_symbol_chunks_p9 (
    essential_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_essential_symbol_chunks_p9_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_essential_symbol_chunks_p9_essential_id_check CHECK (((essential_id % (16)::bigint) = 9)),
    CONSTRAINT codeintel_essential_symbol_chunks_p9_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_essential_symbol_chunks_p9 ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_essentials (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
)
PARTITION BY RANGE (hash);

CREATE TABLE codeintel_essentials_p0 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p1 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p10 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p11 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p12 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p13 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p14 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p15 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p2 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p3 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p4 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p5 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p6 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p7 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p8 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_essentials_p9 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    hash bytea NOT NULL,
    order_key bytea NOT NULL,
    CONSTRAINT codeintel_essentials_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_essentials_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_implementation_occurrences_p0 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p0_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p0_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 0)),
    CONSTRAINT codeintel_implementation_occurrences_p0_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p0 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p1 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p1_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p1_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 1)),
    CONSTRAINT codeintel_implementation_occurrences_p1_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p1 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p10 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p10_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p10_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 10)),
    CONSTRAINT codeintel_implementation_occurrences_p10_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p10 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p11 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p11_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p11_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 11)),
    CONSTRAINT codeintel_implementation_occurrences_p11_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p11 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p12 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p12_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p12_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 12)),
    CONSTRAINT codeintel_implementation_occurrences_p12_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p12 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p13 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p13_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p13_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 13)),
    CONSTRAINT codeintel_implementation_occurrences_p13_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p13 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p14 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p14_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p14_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 14)),
    CONSTRAINT codeintel_implementation_occurrences_p14_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p14 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p15 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p15_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p15_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 15)),
    CONSTRAINT codeintel_implementation_occurrences_p15_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p15 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p16 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p16_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p16_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 16)),
    CONSTRAINT codeintel_implementation_occurrences_p16_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p16 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p17 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p17_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p17_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 17)),
    CONSTRAINT codeintel_implementation_occurrences_p17_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p17 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p18 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p18_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p18_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 18)),
    CONSTRAINT codeintel_implementation_occurrences_p18_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p18 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p19 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p19_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p19_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 19)),
    CONSTRAINT codeintel_implementation_occurrences_p19_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p19 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p2 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p2_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p2_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 2)),
    CONSTRAINT codeintel_implementation_occurrences_p2_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p2 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p20 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p20_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p20_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 20)),
    CONSTRAINT codeintel_implementation_occurrences_p20_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p20 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p21 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p21_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p21_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 21)),
    CONSTRAINT codeintel_implementation_occurrences_p21_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p21 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p22 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p22_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p22_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 22)),
    CONSTRAINT codeintel_implementation_occurrences_p22_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p22 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p23 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p23_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p23_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 23)),
    CONSTRAINT codeintel_implementation_occurrences_p23_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p23 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p24 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p24_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p24_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 24)),
    CONSTRAINT codeintel_implementation_occurrences_p24_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p24 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p25 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p25_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p25_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 25)),
    CONSTRAINT codeintel_implementation_occurrences_p25_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p25 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p26 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p26_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p26_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 26)),
    CONSTRAINT codeintel_implementation_occurrences_p26_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p26 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p27 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p27_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p27_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 27)),
    CONSTRAINT codeintel_implementation_occurrences_p27_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p27 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p28 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p28_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p28_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 28)),
    CONSTRAINT codeintel_implementation_occurrences_p28_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p28 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p29 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p29_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p29_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 29)),
    CONSTRAINT codeintel_implementation_occurrences_p29_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p29 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p3 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p3_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p3_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 3)),
    CONSTRAINT codeintel_implementation_occurrences_p3_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p3 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p30 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p30_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p30_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 30)),
    CONSTRAINT codeintel_implementation_occurrences_p30_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p30 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p31 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p31_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p31_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 31)),
    CONSTRAINT codeintel_implementation_occurrences_p31_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p31 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p32 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p32_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p32_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 32)),
    CONSTRAINT codeintel_implementation_occurrences_p32_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p32 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p33 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p33_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p33_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 33)),
    CONSTRAINT codeintel_implementation_occurrences_p33_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p33 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p34 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p34_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p34_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 34)),
    CONSTRAINT codeintel_implementation_occurrences_p34_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p34 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p35 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p35_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p35_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 35)),
    CONSTRAINT codeintel_implementation_occurrences_p35_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p35 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p36 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p36_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p36_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 36)),
    CONSTRAINT codeintel_implementation_occurrences_p36_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p36 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p37 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p37_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p37_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 37)),
    CONSTRAINT codeintel_implementation_occurrences_p37_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p37 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p38 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p38_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p38_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 38)),
    CONSTRAINT codeintel_implementation_occurrences_p38_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p38 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p39 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p39_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p39_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 39)),
    CONSTRAINT codeintel_implementation_occurrences_p39_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p39 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p4 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p4_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p4_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 4)),
    CONSTRAINT codeintel_implementation_occurrences_p4_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p4 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p40 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p40_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p40_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 40)),
    CONSTRAINT codeintel_implementation_occurrences_p40_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p40 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p41 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p41_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p41_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 41)),
    CONSTRAINT codeintel_implementation_occurrences_p41_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p41 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p42 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p42_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p42_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 42)),
    CONSTRAINT codeintel_implementation_occurrences_p42_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p42 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p43 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p43_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p43_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 43)),
    CONSTRAINT codeintel_implementation_occurrences_p43_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p43 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p44 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p44_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p44_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 44)),
    CONSTRAINT codeintel_implementation_occurrences_p44_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p44 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p45 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p45_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p45_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 45)),
    CONSTRAINT codeintel_implementation_occurrences_p45_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p45 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p46 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p46_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p46_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 46)),
    CONSTRAINT codeintel_implementation_occurrences_p46_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p46 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p47 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p47_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p47_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 47)),
    CONSTRAINT codeintel_implementation_occurrences_p47_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p47 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p48 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p48_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p48_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 48)),
    CONSTRAINT codeintel_implementation_occurrences_p48_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p48 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p49 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p49_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p49_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 49)),
    CONSTRAINT codeintel_implementation_occurrences_p49_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p49 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p5 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p5_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p5_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 5)),
    CONSTRAINT codeintel_implementation_occurrences_p5_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p5 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p50 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p50_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p50_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 50)),
    CONSTRAINT codeintel_implementation_occurrences_p50_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p50 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p51 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p51_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p51_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 51)),
    CONSTRAINT codeintel_implementation_occurrences_p51_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p51 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p52 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p52_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p52_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 52)),
    CONSTRAINT codeintel_implementation_occurrences_p52_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p52 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p53 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p53_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p53_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 53)),
    CONSTRAINT codeintel_implementation_occurrences_p53_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p53 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p54 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p54_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p54_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 54)),
    CONSTRAINT codeintel_implementation_occurrences_p54_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p54 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p55 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p55_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p55_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 55)),
    CONSTRAINT codeintel_implementation_occurrences_p55_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p55 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p56 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p56_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p56_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 56)),
    CONSTRAINT codeintel_implementation_occurrences_p56_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p56 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p57 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p57_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p57_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 57)),
    CONSTRAINT codeintel_implementation_occurrences_p57_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p57 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p58 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p58_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p58_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 58)),
    CONSTRAINT codeintel_implementation_occurrences_p58_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p58 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p59 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p59_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p59_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 59)),
    CONSTRAINT codeintel_implementation_occurrences_p59_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p59 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p6 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p6_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p6_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 6)),
    CONSTRAINT codeintel_implementation_occurrences_p6_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p6 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p60 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p60_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p60_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 60)),
    CONSTRAINT codeintel_implementation_occurrences_p60_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p60 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p61 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p61_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p61_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 61)),
    CONSTRAINT codeintel_implementation_occurrences_p61_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p61 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p62 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p62_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p62_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 62)),
    CONSTRAINT codeintel_implementation_occurrences_p62_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p62 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p63 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p63_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p63_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 63)),
    CONSTRAINT codeintel_implementation_occurrences_p63_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p63 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p7 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p7_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p7_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 7)),
    CONSTRAINT codeintel_implementation_occurrences_p7_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p7 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p8 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p8_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p8_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 8)),
    CONSTRAINT codeintel_implementation_occurrences_p8_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p8 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_implementation_occurrences_p9 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_implementation_occurrences_p9_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_implementation_occurrences_p9_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 9)),
    CONSTRAINT codeintel_implementation_occurrences_p9_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_implementation_occurrences_p9 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_index_external_ids (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    external_id bigint NOT NULL,
    index_id bigint NOT NULL,
    CONSTRAINT codeintel_index_external_ids_external_id_check CHECK ((external_id > 0)),
    CONSTRAINT codeintel_index_external_ids_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_index_package_version_essential_chunks (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    index_package_version_id integer NOT NULL,
    bucket integer NOT NULL,
    bitmap bytea NOT NULL,
    CONSTRAINT codeintel_index_package_version_essential_chunks_bucket_check CHECK ((bucket >= 0)),
    CONSTRAINT codeintel_index_package_version_essential_chunks_tenant_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_index_package_version_essential_chunks ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE codeintel_index_package_versions (
    id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer NOT NULL,
    essential_count integer NOT NULL,
    token smallint NOT NULL,
    hash bytea NOT NULL,
    value text NOT NULL,
    CONSTRAINT codeintel_index_package_versions_essential_count_check CHECK ((essential_count >= 0)),
    CONSTRAINT codeintel_index_package_versions_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_index_package_versions_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE SEQUENCE codeintel_index_package_versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_index_package_versions_id_seq OWNED BY codeintel_index_package_versions.id;

CREATE TABLE codeintel_indexes (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    document_manifest_id bigint NOT NULL,
    package_versions_hash bytea NOT NULL,
    package_versions bytea NOT NULL,
    state text NOT NULL,
    CONSTRAINT codeintel_indexes_package_versions_hash_check CHECK ((octet_length(package_versions_hash) = 32)),
    CONSTRAINT codeintel_indexes_state_check CHECK ((state = ANY (ARRAY['pending'::text, 'completed'::text]))),
    CONSTRAINT codeintel_indexes_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_indexes ALTER COLUMN package_versions SET STORAGE EXTERNAL;

CREATE SEQUENCE codeintel_indexes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_indexes_id_seq OWNED BY codeintel_indexes.id;

CREATE TABLE codeintel_last_reconcile (
    dump_id integer NOT NULL,
    last_reconcile_at timestamp with time zone NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_last_reconcile IS 'Stores the last time processed LSIF data was reconciled with the other database.';

CREATE TABLE codeintel_packages (
    id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    scheme text NOT NULL,
    manager text NOT NULL,
    name text NOT NULL,
    CONSTRAINT codeintel_packages_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE SEQUENCE codeintel_packages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_packages_id_seq OWNED BY codeintel_packages.id;

CREATE TABLE codeintel_reference_occurrences_p0 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p0_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p0_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 0)),
    CONSTRAINT codeintel_reference_occurrences_p0_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p0 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p1 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p1_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p1_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 1)),
    CONSTRAINT codeintel_reference_occurrences_p1_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p1 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p10 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p10_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p10_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 10)),
    CONSTRAINT codeintel_reference_occurrences_p10_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p10 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p11 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p11_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p11_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 11)),
    CONSTRAINT codeintel_reference_occurrences_p11_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p11 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p12 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p12_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p12_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 12)),
    CONSTRAINT codeintel_reference_occurrences_p12_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p12 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p13 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p13_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p13_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 13)),
    CONSTRAINT codeintel_reference_occurrences_p13_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p13 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p14 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p14_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p14_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 14)),
    CONSTRAINT codeintel_reference_occurrences_p14_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p14 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p15 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p15_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p15_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 15)),
    CONSTRAINT codeintel_reference_occurrences_p15_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p15 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p16 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p16_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p16_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 16)),
    CONSTRAINT codeintel_reference_occurrences_p16_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p16 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p17 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p17_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p17_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 17)),
    CONSTRAINT codeintel_reference_occurrences_p17_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p17 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p18 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p18_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p18_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 18)),
    CONSTRAINT codeintel_reference_occurrences_p18_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p18 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p19 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p19_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p19_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 19)),
    CONSTRAINT codeintel_reference_occurrences_p19_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p19 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p2 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p2_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p2_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 2)),
    CONSTRAINT codeintel_reference_occurrences_p2_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p2 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p20 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p20_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p20_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 20)),
    CONSTRAINT codeintel_reference_occurrences_p20_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p20 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p21 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p21_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p21_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 21)),
    CONSTRAINT codeintel_reference_occurrences_p21_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p21 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p22 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p22_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p22_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 22)),
    CONSTRAINT codeintel_reference_occurrences_p22_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p22 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p23 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p23_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p23_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 23)),
    CONSTRAINT codeintel_reference_occurrences_p23_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p23 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p24 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p24_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p24_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 24)),
    CONSTRAINT codeintel_reference_occurrences_p24_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p24 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p25 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p25_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p25_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 25)),
    CONSTRAINT codeintel_reference_occurrences_p25_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p25 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p26 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p26_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p26_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 26)),
    CONSTRAINT codeintel_reference_occurrences_p26_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p26 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p27 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p27_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p27_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 27)),
    CONSTRAINT codeintel_reference_occurrences_p27_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p27 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p28 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p28_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p28_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 28)),
    CONSTRAINT codeintel_reference_occurrences_p28_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p28 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p29 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p29_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p29_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 29)),
    CONSTRAINT codeintel_reference_occurrences_p29_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p29 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p3 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p3_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p3_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 3)),
    CONSTRAINT codeintel_reference_occurrences_p3_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p3 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p30 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p30_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p30_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 30)),
    CONSTRAINT codeintel_reference_occurrences_p30_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p30 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p31 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p31_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p31_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 31)),
    CONSTRAINT codeintel_reference_occurrences_p31_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p31 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p32 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p32_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p32_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 32)),
    CONSTRAINT codeintel_reference_occurrences_p32_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p32 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p33 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p33_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p33_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 33)),
    CONSTRAINT codeintel_reference_occurrences_p33_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p33 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p34 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p34_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p34_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 34)),
    CONSTRAINT codeintel_reference_occurrences_p34_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p34 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p35 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p35_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p35_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 35)),
    CONSTRAINT codeintel_reference_occurrences_p35_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p35 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p36 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p36_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p36_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 36)),
    CONSTRAINT codeintel_reference_occurrences_p36_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p36 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p37 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p37_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p37_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 37)),
    CONSTRAINT codeintel_reference_occurrences_p37_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p37 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p38 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p38_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p38_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 38)),
    CONSTRAINT codeintel_reference_occurrences_p38_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p38 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p39 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p39_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p39_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 39)),
    CONSTRAINT codeintel_reference_occurrences_p39_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p39 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p4 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p4_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p4_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 4)),
    CONSTRAINT codeintel_reference_occurrences_p4_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p4 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p40 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p40_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p40_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 40)),
    CONSTRAINT codeintel_reference_occurrences_p40_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p40 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p41 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p41_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p41_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 41)),
    CONSTRAINT codeintel_reference_occurrences_p41_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p41 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p42 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p42_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p42_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 42)),
    CONSTRAINT codeintel_reference_occurrences_p42_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p42 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p43 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p43_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p43_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 43)),
    CONSTRAINT codeintel_reference_occurrences_p43_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p43 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p44 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p44_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p44_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 44)),
    CONSTRAINT codeintel_reference_occurrences_p44_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p44 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p45 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p45_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p45_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 45)),
    CONSTRAINT codeintel_reference_occurrences_p45_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p45 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p46 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p46_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p46_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 46)),
    CONSTRAINT codeintel_reference_occurrences_p46_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p46 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p47 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p47_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p47_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 47)),
    CONSTRAINT codeintel_reference_occurrences_p47_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p47 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p48 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p48_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p48_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 48)),
    CONSTRAINT codeintel_reference_occurrences_p48_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p48 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p49 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p49_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p49_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 49)),
    CONSTRAINT codeintel_reference_occurrences_p49_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p49 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p5 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p5_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p5_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 5)),
    CONSTRAINT codeintel_reference_occurrences_p5_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p5 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p50 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p50_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p50_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 50)),
    CONSTRAINT codeintel_reference_occurrences_p50_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p50 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p51 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p51_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p51_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 51)),
    CONSTRAINT codeintel_reference_occurrences_p51_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p51 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p52 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p52_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p52_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 52)),
    CONSTRAINT codeintel_reference_occurrences_p52_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p52 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p53 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p53_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p53_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 53)),
    CONSTRAINT codeintel_reference_occurrences_p53_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p53 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p54 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p54_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p54_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 54)),
    CONSTRAINT codeintel_reference_occurrences_p54_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p54 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p55 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p55_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p55_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 55)),
    CONSTRAINT codeintel_reference_occurrences_p55_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p55 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p56 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p56_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p56_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 56)),
    CONSTRAINT codeintel_reference_occurrences_p56_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p56 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p57 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p57_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p57_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 57)),
    CONSTRAINT codeintel_reference_occurrences_p57_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p57 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p58 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p58_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p58_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 58)),
    CONSTRAINT codeintel_reference_occurrences_p58_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p58 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p59 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p59_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p59_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 59)),
    CONSTRAINT codeintel_reference_occurrences_p59_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p59 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p6 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p6_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p6_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 6)),
    CONSTRAINT codeintel_reference_occurrences_p6_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p6 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p60 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p60_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p60_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 60)),
    CONSTRAINT codeintel_reference_occurrences_p60_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p60 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p61 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p61_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p61_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 61)),
    CONSTRAINT codeintel_reference_occurrences_p61_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p61 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p62 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p62_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p62_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 62)),
    CONSTRAINT codeintel_reference_occurrences_p62_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p62 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p63 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p63_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p63_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 63)),
    CONSTRAINT codeintel_reference_occurrences_p63_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p63 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p7 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p7_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p7_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 7)),
    CONSTRAINT codeintel_reference_occurrences_p7_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p7 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p8 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p8_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p8_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 8)),
    CONSTRAINT codeintel_reference_occurrences_p8_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p8 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_reference_occurrences_p9 (
    symbol_id bigint NOT NULL,
    scope_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    essential_id bigint NOT NULL,
    range_count integer NOT NULL,
    version_token smallint NOT NULL,
    order_key bytea NOT NULL,
    ranges bytea NOT NULL,
    CONSTRAINT codeintel_reference_occurrences_p9_range_count_check CHECK ((range_count > 0)),
    CONSTRAINT codeintel_reference_occurrences_p9_symbol_id_check CHECK (((symbol_id % (64)::bigint) = 9)),
    CONSTRAINT codeintel_reference_occurrences_p9_tenant_id_check CHECK ((tenant_id > 0))
);
ALTER TABLE ONLY codeintel_reference_occurrences_p9 ALTER COLUMN ranges SET STORAGE EXTERNAL;

CREATE TABLE codeintel_scip_document_lookup (
    id bigint NOT NULL,
    upload_id integer NOT NULL,
    document_path text NOT NULL,
    document_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_scip_document_lookup IS 'A mapping from file paths to document references within a particular SCIP index.';

COMMENT ON COLUMN codeintel_scip_document_lookup.id IS 'An auto-generated identifier. This column is used as a foreign key target to reduce occurrences of the full document path value.';

COMMENT ON COLUMN codeintel_scip_document_lookup.upload_id IS 'The identifier of the upload that provided this SCIP index.';

COMMENT ON COLUMN codeintel_scip_document_lookup.document_path IS 'The file path to the document relative to the root of the index.';

COMMENT ON COLUMN codeintel_scip_document_lookup.document_id IS 'The foreign key to the shared document payload (see the table [`codeintel_scip_document_lookup`](#table-publiccodeintel_scip_document_lookup)).';

CREATE SEQUENCE codeintel_scip_document_lookup_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_scip_document_lookup_id_seq OWNED BY codeintel_scip_document_lookup.id;

CREATE TABLE codeintel_scip_document_lookup_schema_versions (
    upload_id integer NOT NULL,
    min_schema_version integer,
    max_schema_version integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_scip_document_lookup_schema_versions IS 'Tracks the range of `schema_versions` values associated with each SCIP index in the [`codeintel_scip_document_lookup`](#table-publiccodeintel_scip_document_lookup) table.';

COMMENT ON COLUMN codeintel_scip_document_lookup_schema_versions.upload_id IS 'The identifier of the associated SCIP index.';

COMMENT ON COLUMN codeintel_scip_document_lookup_schema_versions.min_schema_version IS 'A lower-bound on the `schema_version` values of the records in the table [`codeintel_scip_document_lookup`](#table-publiccodeintel_scip_document_lookup) where the `upload_id` column matches the associated SCIP index.';

COMMENT ON COLUMN codeintel_scip_document_lookup_schema_versions.max_schema_version IS 'An upper-bound on the `schema_version` values of the records in the table [`codeintel_scip_document_lookup`](#table-publiccodeintel_scip_document_lookup) where the `upload_id` column matches the associated SCIP index.';

CREATE TABLE codeintel_scip_documents (
    id bigint NOT NULL,
    payload_hash bytea NOT NULL,
    schema_version integer NOT NULL,
    raw_scip_payload bytea NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_scip_documents IS 'A lookup of SCIP [Document](https://sourcegraph.com/search?q=context:%40sourcegraph/all+repo:%5Egithub%5C.com/sourcegraph/scip%24+file:%5Escip%5C.proto+message+Document&patternType=standard) payloads by their hash.';

COMMENT ON COLUMN codeintel_scip_documents.id IS 'An auto-generated identifier. This column is used as a foreign key target to reduce occurrences of the full payload hash value.';

COMMENT ON COLUMN codeintel_scip_documents.payload_hash IS 'A deterministic hash of the raw SCIP payload. We use this as a unique value to enforce deduplication between indexes with the same document data.';

COMMENT ON COLUMN codeintel_scip_documents.schema_version IS 'The schema version of this row - used to determine presence and encoding of (future) denormalized data.';

COMMENT ON COLUMN codeintel_scip_documents.raw_scip_payload IS 'The raw, canonicalized SCIP [Document](https://sourcegraph.com/search?q=context:%40sourcegraph/all+repo:%5Egithub%5C.com/sourcegraph/scip%24+file:%5Escip%5C.proto+message+Document&patternType=standard) payload.';

CREATE TABLE codeintel_scip_documents_dereference_logs (
    id bigint NOT NULL,
    document_id bigint NOT NULL,
    last_removal_time timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_scip_documents_dereference_logs IS 'A list of document rows that were recently dereferenced by the deletion of an index.';

COMMENT ON COLUMN codeintel_scip_documents_dereference_logs.document_id IS 'The identifier of the document that was dereferenced.';

COMMENT ON COLUMN codeintel_scip_documents_dereference_logs.last_removal_time IS 'The time that the log entry was inserted.';

CREATE SEQUENCE codeintel_scip_documents_dereference_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_scip_documents_dereference_logs_id_seq OWNED BY codeintel_scip_documents_dereference_logs.id;

CREATE SEQUENCE codeintel_scip_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_scip_documents_id_seq OWNED BY codeintel_scip_documents.id;

CREATE TABLE codeintel_scip_metadata (
    id bigint NOT NULL,
    upload_id integer NOT NULL,
    tool_name text NOT NULL,
    tool_version text NOT NULL,
    tool_arguments text[] NOT NULL,
    text_document_encoding text NOT NULL,
    protocol_version integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_scip_metadata IS 'Global metadatadata about a single processed upload.';

COMMENT ON COLUMN codeintel_scip_metadata.id IS 'An auto-generated identifier.';

COMMENT ON COLUMN codeintel_scip_metadata.upload_id IS 'The identifier of the upload that provided this SCIP index.';

COMMENT ON COLUMN codeintel_scip_metadata.tool_name IS 'Name of the indexer that produced this index.';

COMMENT ON COLUMN codeintel_scip_metadata.tool_version IS 'Version of the indexer that produced this index.';

COMMENT ON COLUMN codeintel_scip_metadata.tool_arguments IS 'Command-line arguments that were used to invoke this indexer.';

COMMENT ON COLUMN codeintel_scip_metadata.text_document_encoding IS 'The encoding of the text documents within this index. May affect range boundaries.';

COMMENT ON COLUMN codeintel_scip_metadata.protocol_version IS 'The version of the SCIP protocol used to encode this index.';

CREATE SEQUENCE codeintel_scip_metadata_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_scip_metadata_id_seq OWNED BY codeintel_scip_metadata.id;

CREATE TABLE codeintel_scip_symbol_names (
    id integer NOT NULL,
    upload_id integer NOT NULL,
    name_segment text NOT NULL,
    prefix_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_scip_symbol_names IS 'Stores a prefix tree of symbol names within a particular upload.';

COMMENT ON COLUMN codeintel_scip_symbol_names.id IS 'An identifier unique within the index for this symbol name segment.';

COMMENT ON COLUMN codeintel_scip_symbol_names.upload_id IS 'The identifier of the upload that provided this SCIP index.';

COMMENT ON COLUMN codeintel_scip_symbol_names.name_segment IS 'The portion of the symbol name that is unique to this symbol and its children.';

COMMENT ON COLUMN codeintel_scip_symbol_names.prefix_id IS 'The identifier of the segment that forms the prefix of this symbol, if any.';

CREATE TABLE codeintel_scip_symbols (
    upload_id integer NOT NULL,
    document_lookup_id bigint NOT NULL,
    schema_version integer NOT NULL,
    definition_ranges bytea,
    reference_ranges bytea,
    implementation_ranges bytea,
    type_definition_ranges bytea,
    symbol_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_scip_symbols IS 'A mapping from SCIP [Symbol names](https://sourcegraph.com/search?q=context:%40sourcegraph/all+repo:%5Egithub%5C.com/sourcegraph/scip%24+file:%5Escip%5C.proto+message+Symbol&patternType=standard) to path and ranges where that symbol occurs within a particular SCIP index.';

COMMENT ON COLUMN codeintel_scip_symbols.upload_id IS 'The identifier of the upload that provided this SCIP index.';

COMMENT ON COLUMN codeintel_scip_symbols.document_lookup_id IS 'A reference to the `id` column of [`codeintel_scip_document_lookup`](#table-publiccodeintel_scip_document_lookup). Joining on this table yields the document path relative to the index root.';

COMMENT ON COLUMN codeintel_scip_symbols.schema_version IS 'The schema version of this row - used to determine presence and encoding of denormalized data.';

COMMENT ON COLUMN codeintel_scip_symbols.definition_ranges IS 'An encoded set of ranges within the associated document that have a **definition** relationship to the associated symbol.';

COMMENT ON COLUMN codeintel_scip_symbols.reference_ranges IS 'An encoded set of ranges within the associated document that have a **reference** relationship to the associated symbol.';

COMMENT ON COLUMN codeintel_scip_symbols.implementation_ranges IS 'An encoded set of ranges within the associated document that have a **implementation** relationship to the associated symbol.';

COMMENT ON COLUMN codeintel_scip_symbols.type_definition_ranges IS 'An encoded set of ranges within the associated document that have a **type definition** relationship to the associated symbol.';

COMMENT ON COLUMN codeintel_scip_symbols.symbol_id IS 'The identifier of the segment that terminates the name of this symbol. See the table [`codeintel_scip_symbol_names`](#table-publiccodeintel_scip_symbol_names) on how to reconstruct the full symbol name.';

CREATE TABLE codeintel_scip_symbols_schema_versions (
    upload_id integer NOT NULL,
    min_schema_version integer,
    max_schema_version integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_scip_symbols_schema_versions IS 'Tracks the range of `schema_versions` for each index in the [`codeintel_scip_symbols`](#table-publiccodeintel_scip_symbols) table.';

COMMENT ON COLUMN codeintel_scip_symbols_schema_versions.upload_id IS 'The identifier of the associated SCIP index.';

COMMENT ON COLUMN codeintel_scip_symbols_schema_versions.min_schema_version IS 'A lower-bound on the `schema_version` values of the records in the table [`codeintel_scip_symbols`](#table-publiccodeintel_scip_symbols) where the `upload_id` column matches the associated SCIP index.';

COMMENT ON COLUMN codeintel_scip_symbols_schema_versions.max_schema_version IS 'An upper-bound on the `schema_version` values of the records in the table [`codeintel_scip_symbols`](#table-publiccodeintel_scip_symbols) where the `upload_id` column matches the associated SCIP index.';

CREATE TABLE codeintel_scopes (
    id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    repository_id bigint NOT NULL,
    hash bytea NOT NULL,
    root text NOT NULL,
    indexer text NOT NULL,
    CONSTRAINT codeintel_scopes_hash_check CHECK ((octet_length(hash) = 32)),
    CONSTRAINT codeintel_scopes_repository_id_check CHECK ((repository_id > 0)),
    CONSTRAINT codeintel_scopes_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE SEQUENCE codeintel_scopes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_scopes_id_seq OWNED BY codeintel_scopes.id;

CREATE SEQUENCE codeintel_symbol_id_seq_p0
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p1
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p10
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p11
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p12
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p13
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p14
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p15
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p16
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p17
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p18
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p19
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p2
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p20
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p21
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p22
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p23
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p24
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p25
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p26
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p27
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p28
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p29
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p3
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p30
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p31
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p32
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p33
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p34
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p35
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p36
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p37
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p38
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p39
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p4
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p40
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p41
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p42
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p43
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p44
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p45
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p46
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p47
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p48
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p49
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p5
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p50
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p51
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p52
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p53
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p54
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p55
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p56
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p57
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p58
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p59
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p6
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p60
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p61
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p62
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p63
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p7
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p8
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE SEQUENCE codeintel_symbol_id_seq_p9
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 144115188075855871
    CACHE 1;

CREATE TABLE codeintel_symbols_p0 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p0_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 0))),
    CONSTRAINT codeintel_symbols_p0_id_check CHECK (((id % (64)::bigint) = 0)),
    CONSTRAINT codeintel_symbols_p0_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p1 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p1_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 1))),
    CONSTRAINT codeintel_symbols_p1_id_check CHECK (((id % (64)::bigint) = 1)),
    CONSTRAINT codeintel_symbols_p1_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p10 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p10_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 10))),
    CONSTRAINT codeintel_symbols_p10_id_check CHECK (((id % (64)::bigint) = 10)),
    CONSTRAINT codeintel_symbols_p10_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p11 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p11_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 11))),
    CONSTRAINT codeintel_symbols_p11_id_check CHECK (((id % (64)::bigint) = 11)),
    CONSTRAINT codeintel_symbols_p11_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p12 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p12_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 12))),
    CONSTRAINT codeintel_symbols_p12_id_check CHECK (((id % (64)::bigint) = 12)),
    CONSTRAINT codeintel_symbols_p12_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p13 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p13_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 13))),
    CONSTRAINT codeintel_symbols_p13_id_check CHECK (((id % (64)::bigint) = 13)),
    CONSTRAINT codeintel_symbols_p13_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p14 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p14_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 14))),
    CONSTRAINT codeintel_symbols_p14_id_check CHECK (((id % (64)::bigint) = 14)),
    CONSTRAINT codeintel_symbols_p14_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p15 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p15_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 15))),
    CONSTRAINT codeintel_symbols_p15_id_check CHECK (((id % (64)::bigint) = 15)),
    CONSTRAINT codeintel_symbols_p15_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p16 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p16_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 16))),
    CONSTRAINT codeintel_symbols_p16_id_check CHECK (((id % (64)::bigint) = 16)),
    CONSTRAINT codeintel_symbols_p16_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p17 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p17_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 17))),
    CONSTRAINT codeintel_symbols_p17_id_check CHECK (((id % (64)::bigint) = 17)),
    CONSTRAINT codeintel_symbols_p17_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p18 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p18_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 18))),
    CONSTRAINT codeintel_symbols_p18_id_check CHECK (((id % (64)::bigint) = 18)),
    CONSTRAINT codeintel_symbols_p18_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p19 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p19_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 19))),
    CONSTRAINT codeintel_symbols_p19_id_check CHECK (((id % (64)::bigint) = 19)),
    CONSTRAINT codeintel_symbols_p19_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p2 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p2_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 2))),
    CONSTRAINT codeintel_symbols_p2_id_check CHECK (((id % (64)::bigint) = 2)),
    CONSTRAINT codeintel_symbols_p2_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p20 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p20_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 20))),
    CONSTRAINT codeintel_symbols_p20_id_check CHECK (((id % (64)::bigint) = 20)),
    CONSTRAINT codeintel_symbols_p20_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p21 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p21_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 21))),
    CONSTRAINT codeintel_symbols_p21_id_check CHECK (((id % (64)::bigint) = 21)),
    CONSTRAINT codeintel_symbols_p21_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p22 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p22_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 22))),
    CONSTRAINT codeintel_symbols_p22_id_check CHECK (((id % (64)::bigint) = 22)),
    CONSTRAINT codeintel_symbols_p22_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p23 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p23_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 23))),
    CONSTRAINT codeintel_symbols_p23_id_check CHECK (((id % (64)::bigint) = 23)),
    CONSTRAINT codeintel_symbols_p23_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p24 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p24_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 24))),
    CONSTRAINT codeintel_symbols_p24_id_check CHECK (((id % (64)::bigint) = 24)),
    CONSTRAINT codeintel_symbols_p24_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p25 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p25_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 25))),
    CONSTRAINT codeintel_symbols_p25_id_check CHECK (((id % (64)::bigint) = 25)),
    CONSTRAINT codeintel_symbols_p25_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p26 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p26_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 26))),
    CONSTRAINT codeintel_symbols_p26_id_check CHECK (((id % (64)::bigint) = 26)),
    CONSTRAINT codeintel_symbols_p26_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p27 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p27_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 27))),
    CONSTRAINT codeintel_symbols_p27_id_check CHECK (((id % (64)::bigint) = 27)),
    CONSTRAINT codeintel_symbols_p27_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p28 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p28_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 28))),
    CONSTRAINT codeintel_symbols_p28_id_check CHECK (((id % (64)::bigint) = 28)),
    CONSTRAINT codeintel_symbols_p28_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p29 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p29_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 29))),
    CONSTRAINT codeintel_symbols_p29_id_check CHECK (((id % (64)::bigint) = 29)),
    CONSTRAINT codeintel_symbols_p29_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p3 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p3_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 3))),
    CONSTRAINT codeintel_symbols_p3_id_check CHECK (((id % (64)::bigint) = 3)),
    CONSTRAINT codeintel_symbols_p3_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p30 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p30_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 30))),
    CONSTRAINT codeintel_symbols_p30_id_check CHECK (((id % (64)::bigint) = 30)),
    CONSTRAINT codeintel_symbols_p30_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p31 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p31_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 31))),
    CONSTRAINT codeintel_symbols_p31_id_check CHECK (((id % (64)::bigint) = 31)),
    CONSTRAINT codeintel_symbols_p31_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p32 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p32_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 32))),
    CONSTRAINT codeintel_symbols_p32_id_check CHECK (((id % (64)::bigint) = 32)),
    CONSTRAINT codeintel_symbols_p32_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p33 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p33_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 33))),
    CONSTRAINT codeintel_symbols_p33_id_check CHECK (((id % (64)::bigint) = 33)),
    CONSTRAINT codeintel_symbols_p33_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p34 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p34_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 34))),
    CONSTRAINT codeintel_symbols_p34_id_check CHECK (((id % (64)::bigint) = 34)),
    CONSTRAINT codeintel_symbols_p34_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p35 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p35_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 35))),
    CONSTRAINT codeintel_symbols_p35_id_check CHECK (((id % (64)::bigint) = 35)),
    CONSTRAINT codeintel_symbols_p35_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p36 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p36_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 36))),
    CONSTRAINT codeintel_symbols_p36_id_check CHECK (((id % (64)::bigint) = 36)),
    CONSTRAINT codeintel_symbols_p36_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p37 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p37_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 37))),
    CONSTRAINT codeintel_symbols_p37_id_check CHECK (((id % (64)::bigint) = 37)),
    CONSTRAINT codeintel_symbols_p37_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p38 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p38_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 38))),
    CONSTRAINT codeintel_symbols_p38_id_check CHECK (((id % (64)::bigint) = 38)),
    CONSTRAINT codeintel_symbols_p38_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p39 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p39_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 39))),
    CONSTRAINT codeintel_symbols_p39_id_check CHECK (((id % (64)::bigint) = 39)),
    CONSTRAINT codeintel_symbols_p39_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p4 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p4_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 4))),
    CONSTRAINT codeintel_symbols_p4_id_check CHECK (((id % (64)::bigint) = 4)),
    CONSTRAINT codeintel_symbols_p4_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p40 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p40_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 40))),
    CONSTRAINT codeintel_symbols_p40_id_check CHECK (((id % (64)::bigint) = 40)),
    CONSTRAINT codeintel_symbols_p40_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p41 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p41_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 41))),
    CONSTRAINT codeintel_symbols_p41_id_check CHECK (((id % (64)::bigint) = 41)),
    CONSTRAINT codeintel_symbols_p41_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p42 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p42_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 42))),
    CONSTRAINT codeintel_symbols_p42_id_check CHECK (((id % (64)::bigint) = 42)),
    CONSTRAINT codeintel_symbols_p42_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p43 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p43_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 43))),
    CONSTRAINT codeintel_symbols_p43_id_check CHECK (((id % (64)::bigint) = 43)),
    CONSTRAINT codeintel_symbols_p43_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p44 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p44_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 44))),
    CONSTRAINT codeintel_symbols_p44_id_check CHECK (((id % (64)::bigint) = 44)),
    CONSTRAINT codeintel_symbols_p44_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p45 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p45_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 45))),
    CONSTRAINT codeintel_symbols_p45_id_check CHECK (((id % (64)::bigint) = 45)),
    CONSTRAINT codeintel_symbols_p45_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p46 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p46_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 46))),
    CONSTRAINT codeintel_symbols_p46_id_check CHECK (((id % (64)::bigint) = 46)),
    CONSTRAINT codeintel_symbols_p46_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p47 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p47_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 47))),
    CONSTRAINT codeintel_symbols_p47_id_check CHECK (((id % (64)::bigint) = 47)),
    CONSTRAINT codeintel_symbols_p47_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p48 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p48_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 48))),
    CONSTRAINT codeintel_symbols_p48_id_check CHECK (((id % (64)::bigint) = 48)),
    CONSTRAINT codeintel_symbols_p48_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p49 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p49_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 49))),
    CONSTRAINT codeintel_symbols_p49_id_check CHECK (((id % (64)::bigint) = 49)),
    CONSTRAINT codeintel_symbols_p49_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p5 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p5_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 5))),
    CONSTRAINT codeintel_symbols_p5_id_check CHECK (((id % (64)::bigint) = 5)),
    CONSTRAINT codeintel_symbols_p5_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p50 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p50_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 50))),
    CONSTRAINT codeintel_symbols_p50_id_check CHECK (((id % (64)::bigint) = 50)),
    CONSTRAINT codeintel_symbols_p50_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p51 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p51_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 51))),
    CONSTRAINT codeintel_symbols_p51_id_check CHECK (((id % (64)::bigint) = 51)),
    CONSTRAINT codeintel_symbols_p51_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p52 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p52_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 52))),
    CONSTRAINT codeintel_symbols_p52_id_check CHECK (((id % (64)::bigint) = 52)),
    CONSTRAINT codeintel_symbols_p52_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p53 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p53_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 53))),
    CONSTRAINT codeintel_symbols_p53_id_check CHECK (((id % (64)::bigint) = 53)),
    CONSTRAINT codeintel_symbols_p53_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p54 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p54_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 54))),
    CONSTRAINT codeintel_symbols_p54_id_check CHECK (((id % (64)::bigint) = 54)),
    CONSTRAINT codeintel_symbols_p54_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p55 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p55_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 55))),
    CONSTRAINT codeintel_symbols_p55_id_check CHECK (((id % (64)::bigint) = 55)),
    CONSTRAINT codeintel_symbols_p55_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p56 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p56_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 56))),
    CONSTRAINT codeintel_symbols_p56_id_check CHECK (((id % (64)::bigint) = 56)),
    CONSTRAINT codeintel_symbols_p56_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p57 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p57_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 57))),
    CONSTRAINT codeintel_symbols_p57_id_check CHECK (((id % (64)::bigint) = 57)),
    CONSTRAINT codeintel_symbols_p57_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p58 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p58_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 58))),
    CONSTRAINT codeintel_symbols_p58_id_check CHECK (((id % (64)::bigint) = 58)),
    CONSTRAINT codeintel_symbols_p58_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p59 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p59_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 59))),
    CONSTRAINT codeintel_symbols_p59_id_check CHECK (((id % (64)::bigint) = 59)),
    CONSTRAINT codeintel_symbols_p59_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p6 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p6_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 6))),
    CONSTRAINT codeintel_symbols_p6_id_check CHECK (((id % (64)::bigint) = 6)),
    CONSTRAINT codeintel_symbols_p6_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p60 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p60_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 60))),
    CONSTRAINT codeintel_symbols_p60_id_check CHECK (((id % (64)::bigint) = 60)),
    CONSTRAINT codeintel_symbols_p60_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p61 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p61_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 61))),
    CONSTRAINT codeintel_symbols_p61_id_check CHECK (((id % (64)::bigint) = 61)),
    CONSTRAINT codeintel_symbols_p61_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p62 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p62_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 62))),
    CONSTRAINT codeintel_symbols_p62_id_check CHECK (((id % (64)::bigint) = 62)),
    CONSTRAINT codeintel_symbols_p62_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p63 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p63_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 63))),
    CONSTRAINT codeintel_symbols_p63_id_check CHECK (((id % (64)::bigint) = 63)),
    CONSTRAINT codeintel_symbols_p63_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p7 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p7_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 7))),
    CONSTRAINT codeintel_symbols_p7_id_check CHECK (((id % (64)::bigint) = 7)),
    CONSTRAINT codeintel_symbols_p7_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p8 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p8_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 8))),
    CONSTRAINT codeintel_symbols_p8_id_check CHECK (((id % (64)::bigint) = 8)),
    CONSTRAINT codeintel_symbols_p8_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_symbols_p9 (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    package_id integer,
    hash bytea NOT NULL,
    descriptor text NOT NULL,
    CONSTRAINT codeintel_symbols_p9_hash_check CHECK (((octet_length(hash) = 32) AND ((get_byte(hash, 0) >> 2) = 9))),
    CONSTRAINT codeintel_symbols_p9_id_check CHECK (((id % (64)::bigint) = 9)),
    CONSTRAINT codeintel_symbols_p9_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE codeintel_writer_control (
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    owner_epoch bigint DEFAULT 0 NOT NULL,
    CONSTRAINT codeintel_writer_control_tenant_id_check CHECK ((tenant_id > 0))
);

CREATE TABLE rockskip_ancestry (
    id integer NOT NULL,
    repo_id integer NOT NULL,
    commit_id character varying(40) NOT NULL,
    height integer NOT NULL,
    ancestor integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE rockskip_ancestry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE rockskip_ancestry_id_seq OWNED BY rockskip_ancestry.id;

CREATE TABLE rockskip_repos (
    id integer NOT NULL,
    repo text NOT NULL,
    last_accessed_at timestamp with time zone NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE rockskip_repos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE rockskip_repos_id_seq OWNED BY rockskip_repos.id;

CREATE TABLE rockskip_symbols (
    id integer NOT NULL,
    added integer[] NOT NULL,
    deleted integer[] NOT NULL,
    repo_id integer NOT NULL,
    path text NOT NULL,
    name text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE rockskip_symbols_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE rockskip_symbols_id_seq OWNED BY rockskip_symbols.id;

CREATE TABLE tenants (
    id bigint NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    workspace_id uuid NOT NULL,
    display_name text,
    state tenant_state DEFAULT 'active'::tenant_state NOT NULL,
    external_url text DEFAULT ''::text NOT NULL,
    redis_pruned_at timestamp with time zone,
    deleted_at timestamp with time zone,
    gitserver_pruned_at timestamp with time zone,
    zoekt_pruned_at timestamp with time zone,
    blobstore_pruned_at timestamp with time zone,
    database_pruned_at timestamp with time zone,
    searcher_cache_pruned_at timestamp with time zone,
    CONSTRAINT tenant_name_length CHECK (((char_length(name) <= 32) AND (char_length(name) >= 3))),
    CONSTRAINT tenant_name_valid_chars CHECK ((name ~ '^[a-z](?:[a-z0-9\_-])*[a-z0-9]$'::text)),
    CONSTRAINT tenants_external_url_check CHECK ((lower(external_url) = external_url))
);

COMMENT ON TABLE tenants IS 'The table that holds all tenants known to the instance. In enterprise instances, this table will only contain the "default" tenant.';

COMMENT ON COLUMN tenants.id IS 'The ID of the tenant. To keep tenants globally addressable, and be able to move them aronud instances more easily, the ID is NOT a serial and has to be specified explicitly. The creator of the tenant is responsible for choosing a unique ID, if it cares.';

COMMENT ON COLUMN tenants.name IS 'The name of the tenant. This may be displayed to the user and must be unique.';

COMMENT ON COLUMN tenants.workspace_id IS 'The ID in workspaces service of the tenant. This is used for identifying the link between tenant and workspace.';

COMMENT ON COLUMN tenants.display_name IS 'An optional display name for the tenant. This is used for rendering the tenant name in the UI.';

COMMENT ON COLUMN tenants.state IS 'The state of the tenant. Can be active, suspended, dormant or deleted.';

CREATE SEQUENCE tenants_id_seq
    AS integer
    START WITH 2
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE tenants_id_seq OWNED BY tenants.id;

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p0 FOR VALUES FROM ('\x00') TO ('\x10');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p1 FOR VALUES FROM ('\x10') TO ('\x20');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p10 FOR VALUES FROM ('\xa0') TO ('\xb0');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p11 FOR VALUES FROM ('\xb0') TO ('\xc0');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p12 FOR VALUES FROM ('\xc0') TO ('\xd0');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p13 FOR VALUES FROM ('\xd0') TO ('\xe0');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p14 FOR VALUES FROM ('\xe0') TO ('\xf0');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p15 FOR VALUES FROM ('\xf0') TO (MAXVALUE);

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p2 FOR VALUES FROM ('\x20') TO ('\x30');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p3 FOR VALUES FROM ('\x30') TO ('\x40');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p4 FOR VALUES FROM ('\x40') TO ('\x50');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p5 FOR VALUES FROM ('\x50') TO ('\x60');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p6 FOR VALUES FROM ('\x60') TO ('\x70');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p7 FOR VALUES FROM ('\x70') TO ('\x80');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p8 FOR VALUES FROM ('\x80') TO ('\x90');

ALTER TABLE ONLY codeintel_documents ATTACH PARTITION codeintel_documents_p9 FOR VALUES FROM ('\x90') TO ('\xa0');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p0 FOR VALUES FROM ('\x00') TO ('\x10');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p1 FOR VALUES FROM ('\x10') TO ('\x20');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p10 FOR VALUES FROM ('\xa0') TO ('\xb0');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p11 FOR VALUES FROM ('\xb0') TO ('\xc0');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p12 FOR VALUES FROM ('\xc0') TO ('\xd0');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p13 FOR VALUES FROM ('\xd0') TO ('\xe0');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p14 FOR VALUES FROM ('\xe0') TO ('\xf0');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p15 FOR VALUES FROM ('\xf0') TO (MAXVALUE);

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p2 FOR VALUES FROM ('\x20') TO ('\x30');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p3 FOR VALUES FROM ('\x30') TO ('\x40');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p4 FOR VALUES FROM ('\x40') TO ('\x50');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p5 FOR VALUES FROM ('\x50') TO ('\x60');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p6 FOR VALUES FROM ('\x60') TO ('\x70');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p7 FOR VALUES FROM ('\x70') TO ('\x80');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p8 FOR VALUES FROM ('\x80') TO ('\x90');

ALTER TABLE ONLY codeintel_essentials ATTACH PARTITION codeintel_essentials_p9 FOR VALUES FROM ('\x90') TO ('\xa0');

ALTER TABLE ONLY codeintel_document_manifests ALTER COLUMN id SET DEFAULT nextval('codeintel_document_manifests_id_seq'::regclass);

ALTER TABLE ONLY codeintel_essential_manifests ALTER COLUMN id SET DEFAULT nextval('codeintel_essential_manifests_id_seq'::regclass);

ALTER TABLE ONLY codeintel_index_package_versions ALTER COLUMN id SET DEFAULT nextval('codeintel_index_package_versions_id_seq'::regclass);

ALTER TABLE ONLY codeintel_indexes ALTER COLUMN id SET DEFAULT nextval('codeintel_indexes_id_seq'::regclass);

ALTER TABLE ONLY codeintel_packages ALTER COLUMN id SET DEFAULT nextval('codeintel_packages_id_seq'::regclass);

ALTER TABLE ONLY codeintel_scip_document_lookup ALTER COLUMN id SET DEFAULT nextval('codeintel_scip_document_lookup_id_seq'::regclass);

ALTER TABLE ONLY codeintel_scip_documents ALTER COLUMN id SET DEFAULT nextval('codeintel_scip_documents_id_seq'::regclass);

ALTER TABLE ONLY codeintel_scip_documents_dereference_logs ALTER COLUMN id SET DEFAULT nextval('codeintel_scip_documents_dereference_logs_id_seq'::regclass);

ALTER TABLE ONLY codeintel_scip_metadata ALTER COLUMN id SET DEFAULT nextval('codeintel_scip_metadata_id_seq'::regclass);

ALTER TABLE ONLY codeintel_scopes ALTER COLUMN id SET DEFAULT nextval('codeintel_scopes_id_seq'::regclass);

ALTER TABLE ONLY rockskip_ancestry ALTER COLUMN id SET DEFAULT nextval('rockskip_ancestry_id_seq'::regclass);

ALTER TABLE ONLY rockskip_repos ALTER COLUMN id SET DEFAULT nextval('rockskip_repos_id_seq'::regclass);

ALTER TABLE ONLY rockskip_symbols ALTER COLUMN id SET DEFAULT nextval('rockskip_symbols_id_seq'::regclass);

ALTER TABLE ONLY tenants ALTER COLUMN id SET DEFAULT nextval('tenants_id_seq'::regclass);

ALTER TABLE ONLY codeintel_definition_occurrences_p0
    ADD CONSTRAINT codeintel_definition_occurrences_p0_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p10
    ADD CONSTRAINT codeintel_definition_occurrences_p10_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p11
    ADD CONSTRAINT codeintel_definition_occurrences_p11_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p12
    ADD CONSTRAINT codeintel_definition_occurrences_p12_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p13
    ADD CONSTRAINT codeintel_definition_occurrences_p13_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p14
    ADD CONSTRAINT codeintel_definition_occurrences_p14_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p15
    ADD CONSTRAINT codeintel_definition_occurrences_p15_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p16
    ADD CONSTRAINT codeintel_definition_occurrences_p16_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p17
    ADD CONSTRAINT codeintel_definition_occurrences_p17_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p18
    ADD CONSTRAINT codeintel_definition_occurrences_p18_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p19
    ADD CONSTRAINT codeintel_definition_occurrences_p19_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p1
    ADD CONSTRAINT codeintel_definition_occurrences_p1_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p20
    ADD CONSTRAINT codeintel_definition_occurrences_p20_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p21
    ADD CONSTRAINT codeintel_definition_occurrences_p21_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p22
    ADD CONSTRAINT codeintel_definition_occurrences_p22_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p23
    ADD CONSTRAINT codeintel_definition_occurrences_p23_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p24
    ADD CONSTRAINT codeintel_definition_occurrences_p24_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p25
    ADD CONSTRAINT codeintel_definition_occurrences_p25_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p26
    ADD CONSTRAINT codeintel_definition_occurrences_p26_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p27
    ADD CONSTRAINT codeintel_definition_occurrences_p27_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p28
    ADD CONSTRAINT codeintel_definition_occurrences_p28_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p29
    ADD CONSTRAINT codeintel_definition_occurrences_p29_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p2
    ADD CONSTRAINT codeintel_definition_occurrences_p2_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p30
    ADD CONSTRAINT codeintel_definition_occurrences_p30_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p31
    ADD CONSTRAINT codeintel_definition_occurrences_p31_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p32
    ADD CONSTRAINT codeintel_definition_occurrences_p32_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p33
    ADD CONSTRAINT codeintel_definition_occurrences_p33_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p34
    ADD CONSTRAINT codeintel_definition_occurrences_p34_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p35
    ADD CONSTRAINT codeintel_definition_occurrences_p35_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p36
    ADD CONSTRAINT codeintel_definition_occurrences_p36_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p37
    ADD CONSTRAINT codeintel_definition_occurrences_p37_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p38
    ADD CONSTRAINT codeintel_definition_occurrences_p38_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p39
    ADD CONSTRAINT codeintel_definition_occurrences_p39_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p3
    ADD CONSTRAINT codeintel_definition_occurrences_p3_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p40
    ADD CONSTRAINT codeintel_definition_occurrences_p40_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p41
    ADD CONSTRAINT codeintel_definition_occurrences_p41_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p42
    ADD CONSTRAINT codeintel_definition_occurrences_p42_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p43
    ADD CONSTRAINT codeintel_definition_occurrences_p43_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p44
    ADD CONSTRAINT codeintel_definition_occurrences_p44_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p45
    ADD CONSTRAINT codeintel_definition_occurrences_p45_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p46
    ADD CONSTRAINT codeintel_definition_occurrences_p46_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p47
    ADD CONSTRAINT codeintel_definition_occurrences_p47_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p48
    ADD CONSTRAINT codeintel_definition_occurrences_p48_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p49
    ADD CONSTRAINT codeintel_definition_occurrences_p49_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p4
    ADD CONSTRAINT codeintel_definition_occurrences_p4_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p50
    ADD CONSTRAINT codeintel_definition_occurrences_p50_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p51
    ADD CONSTRAINT codeintel_definition_occurrences_p51_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p52
    ADD CONSTRAINT codeintel_definition_occurrences_p52_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p53
    ADD CONSTRAINT codeintel_definition_occurrences_p53_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p54
    ADD CONSTRAINT codeintel_definition_occurrences_p54_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p55
    ADD CONSTRAINT codeintel_definition_occurrences_p55_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p56
    ADD CONSTRAINT codeintel_definition_occurrences_p56_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p57
    ADD CONSTRAINT codeintel_definition_occurrences_p57_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p58
    ADD CONSTRAINT codeintel_definition_occurrences_p58_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p59
    ADD CONSTRAINT codeintel_definition_occurrences_p59_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p5
    ADD CONSTRAINT codeintel_definition_occurrences_p5_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p60
    ADD CONSTRAINT codeintel_definition_occurrences_p60_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p61
    ADD CONSTRAINT codeintel_definition_occurrences_p61_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p62
    ADD CONSTRAINT codeintel_definition_occurrences_p62_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p63
    ADD CONSTRAINT codeintel_definition_occurrences_p63_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p6
    ADD CONSTRAINT codeintel_definition_occurrences_p6_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p7
    ADD CONSTRAINT codeintel_definition_occurrences_p7_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p8
    ADD CONSTRAINT codeintel_definition_occurrences_p8_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_definition_occurrences_p9
    ADD CONSTRAINT codeintel_definition_occurrences_p9_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_document_manifest_chunks
    ADD CONSTRAINT codeintel_document_manifest_chunks_pkey PRIMARY KEY (document_manifest_id, bucket);

ALTER TABLE ONLY codeintel_document_manifests
    ADD CONSTRAINT codeintel_document_manifests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_document_manifests
    ADD CONSTRAINT codeintel_document_manifests_tenant_id_hash_key UNIQUE (tenant_id, hash);

ALTER TABLE ONLY codeintel_document_path_chunks_p0
    ADD CONSTRAINT codeintel_document_path_chunks_p0_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p10
    ADD CONSTRAINT codeintel_document_path_chunks_p10_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p11
    ADD CONSTRAINT codeintel_document_path_chunks_p11_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p12
    ADD CONSTRAINT codeintel_document_path_chunks_p12_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p13
    ADD CONSTRAINT codeintel_document_path_chunks_p13_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p14
    ADD CONSTRAINT codeintel_document_path_chunks_p14_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p15
    ADD CONSTRAINT codeintel_document_path_chunks_p15_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p1
    ADD CONSTRAINT codeintel_document_path_chunks_p1_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p2
    ADD CONSTRAINT codeintel_document_path_chunks_p2_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p3
    ADD CONSTRAINT codeintel_document_path_chunks_p3_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p4
    ADD CONSTRAINT codeintel_document_path_chunks_p4_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p5
    ADD CONSTRAINT codeintel_document_path_chunks_p5_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p6
    ADD CONSTRAINT codeintel_document_path_chunks_p6_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p7
    ADD CONSTRAINT codeintel_document_path_chunks_p7_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p8
    ADD CONSTRAINT codeintel_document_path_chunks_p8_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_path_chunks_p9
    ADD CONSTRAINT codeintel_document_path_chunks_p9_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket);

ALTER TABLE ONLY codeintel_document_paths
    ADD CONSTRAINT codeintel_document_paths_pkey PRIMARY KEY (tenant_id, relative_path);

ALTER TABLE ONLY codeintel_document_paths
    ADD CONSTRAINT codeintel_document_paths_tenant_id_order_key_key UNIQUE (tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_payloads_p0
    ADD CONSTRAINT codeintel_document_payloads_p0_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p10
    ADD CONSTRAINT codeintel_document_payloads_p10_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p11
    ADD CONSTRAINT codeintel_document_payloads_p11_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p12
    ADD CONSTRAINT codeintel_document_payloads_p12_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p13
    ADD CONSTRAINT codeintel_document_payloads_p13_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p14
    ADD CONSTRAINT codeintel_document_payloads_p14_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p15
    ADD CONSTRAINT codeintel_document_payloads_p15_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p1
    ADD CONSTRAINT codeintel_document_payloads_p1_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p2
    ADD CONSTRAINT codeintel_document_payloads_p2_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p3
    ADD CONSTRAINT codeintel_document_payloads_p3_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p4
    ADD CONSTRAINT codeintel_document_payloads_p4_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p5
    ADD CONSTRAINT codeintel_document_payloads_p5_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p6
    ADD CONSTRAINT codeintel_document_payloads_p6_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p7
    ADD CONSTRAINT codeintel_document_payloads_p7_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p8
    ADD CONSTRAINT codeintel_document_payloads_p8_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_document_payloads_p9
    ADD CONSTRAINT codeintel_document_payloads_p9_document_id PRIMARY KEY (document_id, tenant_id);

ALTER TABLE ONLY codeintel_documents
    ADD CONSTRAINT codeintel_documents_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p0
    ADD CONSTRAINT codeintel_documents_p0_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p10
    ADD CONSTRAINT codeintel_documents_p10_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p11
    ADD CONSTRAINT codeintel_documents_p11_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p12
    ADD CONSTRAINT codeintel_documents_p12_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p13
    ADD CONSTRAINT codeintel_documents_p13_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p14
    ADD CONSTRAINT codeintel_documents_p14_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p15
    ADD CONSTRAINT codeintel_documents_p15_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p1
    ADD CONSTRAINT codeintel_documents_p1_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p2
    ADD CONSTRAINT codeintel_documents_p2_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p3
    ADD CONSTRAINT codeintel_documents_p3_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p4
    ADD CONSTRAINT codeintel_documents_p4_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p5
    ADD CONSTRAINT codeintel_documents_p5_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p6
    ADD CONSTRAINT codeintel_documents_p6_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p7
    ADD CONSTRAINT codeintel_documents_p7_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p8
    ADD CONSTRAINT codeintel_documents_p8_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_documents_p9
    ADD CONSTRAINT codeintel_documents_p9_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essential_manifest_chunks
    ADD CONSTRAINT codeintel_essential_manifest_chunks_pkey PRIMARY KEY (essential_manifest_id, bucket);

ALTER TABLE ONLY codeintel_essential_manifests
    ADD CONSTRAINT codeintel_essential_manifests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_essential_manifests
    ADD CONSTRAINT codeintel_essential_manifests_tenant_id_hash_key UNIQUE (tenant_id, hash);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p0
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p0_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p10
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p10_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p11
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p11_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p12
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p12_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p13
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p13_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p14
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p14_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p15
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p15_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p1
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p1_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p2
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p2_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p3
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p3_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p4
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p4_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p5
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p5_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p6
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p6_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p7
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p7_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p8
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p8_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essential_symbol_chunks_p9
    ADD CONSTRAINT codeintel_essential_symbol_chunks_p9_key PRIMARY KEY (essential_id, tenant_id, bucket);

ALTER TABLE ONLY codeintel_essentials
    ADD CONSTRAINT codeintel_essentials_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p0
    ADD CONSTRAINT codeintel_essentials_p0_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p10
    ADD CONSTRAINT codeintel_essentials_p10_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p11
    ADD CONSTRAINT codeintel_essentials_p11_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p12
    ADD CONSTRAINT codeintel_essentials_p12_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p13
    ADD CONSTRAINT codeintel_essentials_p13_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p14
    ADD CONSTRAINT codeintel_essentials_p14_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p15
    ADD CONSTRAINT codeintel_essentials_p15_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p1
    ADD CONSTRAINT codeintel_essentials_p1_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p2
    ADD CONSTRAINT codeintel_essentials_p2_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p3
    ADD CONSTRAINT codeintel_essentials_p3_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p4
    ADD CONSTRAINT codeintel_essentials_p4_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p5
    ADD CONSTRAINT codeintel_essentials_p5_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p6
    ADD CONSTRAINT codeintel_essentials_p6_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p7
    ADD CONSTRAINT codeintel_essentials_p7_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p8
    ADD CONSTRAINT codeintel_essentials_p8_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_essentials_p9
    ADD CONSTRAINT codeintel_essentials_p9_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_implementation_occurrences_p0
    ADD CONSTRAINT codeintel_implementation_occurrences_p0_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p10
    ADD CONSTRAINT codeintel_implementation_occurrences_p10_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p11
    ADD CONSTRAINT codeintel_implementation_occurrences_p11_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p12
    ADD CONSTRAINT codeintel_implementation_occurrences_p12_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p13
    ADD CONSTRAINT codeintel_implementation_occurrences_p13_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p14
    ADD CONSTRAINT codeintel_implementation_occurrences_p14_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p15
    ADD CONSTRAINT codeintel_implementation_occurrences_p15_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p16
    ADD CONSTRAINT codeintel_implementation_occurrences_p16_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p17
    ADD CONSTRAINT codeintel_implementation_occurrences_p17_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p18
    ADD CONSTRAINT codeintel_implementation_occurrences_p18_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p19
    ADD CONSTRAINT codeintel_implementation_occurrences_p19_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p1
    ADD CONSTRAINT codeintel_implementation_occurrences_p1_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p20
    ADD CONSTRAINT codeintel_implementation_occurrences_p20_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p21
    ADD CONSTRAINT codeintel_implementation_occurrences_p21_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p22
    ADD CONSTRAINT codeintel_implementation_occurrences_p22_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p23
    ADD CONSTRAINT codeintel_implementation_occurrences_p23_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p24
    ADD CONSTRAINT codeintel_implementation_occurrences_p24_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p25
    ADD CONSTRAINT codeintel_implementation_occurrences_p25_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p26
    ADD CONSTRAINT codeintel_implementation_occurrences_p26_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p27
    ADD CONSTRAINT codeintel_implementation_occurrences_p27_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p28
    ADD CONSTRAINT codeintel_implementation_occurrences_p28_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p29
    ADD CONSTRAINT codeintel_implementation_occurrences_p29_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p2
    ADD CONSTRAINT codeintel_implementation_occurrences_p2_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p30
    ADD CONSTRAINT codeintel_implementation_occurrences_p30_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p31
    ADD CONSTRAINT codeintel_implementation_occurrences_p31_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p32
    ADD CONSTRAINT codeintel_implementation_occurrences_p32_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p33
    ADD CONSTRAINT codeintel_implementation_occurrences_p33_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p34
    ADD CONSTRAINT codeintel_implementation_occurrences_p34_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p35
    ADD CONSTRAINT codeintel_implementation_occurrences_p35_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p36
    ADD CONSTRAINT codeintel_implementation_occurrences_p36_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p37
    ADD CONSTRAINT codeintel_implementation_occurrences_p37_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p38
    ADD CONSTRAINT codeintel_implementation_occurrences_p38_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p39
    ADD CONSTRAINT codeintel_implementation_occurrences_p39_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p3
    ADD CONSTRAINT codeintel_implementation_occurrences_p3_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p40
    ADD CONSTRAINT codeintel_implementation_occurrences_p40_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p41
    ADD CONSTRAINT codeintel_implementation_occurrences_p41_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p42
    ADD CONSTRAINT codeintel_implementation_occurrences_p42_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p43
    ADD CONSTRAINT codeintel_implementation_occurrences_p43_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p44
    ADD CONSTRAINT codeintel_implementation_occurrences_p44_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p45
    ADD CONSTRAINT codeintel_implementation_occurrences_p45_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p46
    ADD CONSTRAINT codeintel_implementation_occurrences_p46_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p47
    ADD CONSTRAINT codeintel_implementation_occurrences_p47_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p48
    ADD CONSTRAINT codeintel_implementation_occurrences_p48_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p49
    ADD CONSTRAINT codeintel_implementation_occurrences_p49_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p4
    ADD CONSTRAINT codeintel_implementation_occurrences_p4_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p50
    ADD CONSTRAINT codeintel_implementation_occurrences_p50_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p51
    ADD CONSTRAINT codeintel_implementation_occurrences_p51_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p52
    ADD CONSTRAINT codeintel_implementation_occurrences_p52_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p53
    ADD CONSTRAINT codeintel_implementation_occurrences_p53_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p54
    ADD CONSTRAINT codeintel_implementation_occurrences_p54_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p55
    ADD CONSTRAINT codeintel_implementation_occurrences_p55_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p56
    ADD CONSTRAINT codeintel_implementation_occurrences_p56_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p57
    ADD CONSTRAINT codeintel_implementation_occurrences_p57_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p58
    ADD CONSTRAINT codeintel_implementation_occurrences_p58_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p59
    ADD CONSTRAINT codeintel_implementation_occurrences_p59_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p5
    ADD CONSTRAINT codeintel_implementation_occurrences_p5_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p60
    ADD CONSTRAINT codeintel_implementation_occurrences_p60_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p61
    ADD CONSTRAINT codeintel_implementation_occurrences_p61_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p62
    ADD CONSTRAINT codeintel_implementation_occurrences_p62_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p63
    ADD CONSTRAINT codeintel_implementation_occurrences_p63_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p6
    ADD CONSTRAINT codeintel_implementation_occurrences_p6_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p7
    ADD CONSTRAINT codeintel_implementation_occurrences_p7_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p8
    ADD CONSTRAINT codeintel_implementation_occurrences_p8_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_implementation_occurrences_p9
    ADD CONSTRAINT codeintel_implementation_occurrences_p9_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_index_external_ids
    ADD CONSTRAINT codeintel_index_external_ids_pkey PRIMARY KEY (tenant_id, external_id);

ALTER TABLE ONLY codeintel_index_package_version_essential_chunks
    ADD CONSTRAINT codeintel_index_package_version_essential_chunks_pkey PRIMARY KEY (index_package_version_id, bucket);

ALTER TABLE ONLY codeintel_index_package_versions
    ADD CONSTRAINT codeintel_index_package_versions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_index_package_versions
    ADD CONSTRAINT codeintel_index_package_versions_tenant_id_hash_key UNIQUE (tenant_id, hash);

ALTER TABLE ONLY codeintel_indexes
    ADD CONSTRAINT codeintel_indexes_manifest_versions_key UNIQUE (document_manifest_id, package_versions_hash);

ALTER TABLE ONLY codeintel_indexes
    ADD CONSTRAINT codeintel_indexes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_last_reconcile
    ADD CONSTRAINT codeintel_last_reconcile_pkey PRIMARY KEY (dump_id);

ALTER TABLE ONLY codeintel_packages
    ADD CONSTRAINT codeintel_packages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_packages
    ADD CONSTRAINT codeintel_packages_tenant_id_scheme_manager_name_key UNIQUE (tenant_id, scheme, manager, name);

ALTER TABLE ONLY codeintel_reference_occurrences_p0
    ADD CONSTRAINT codeintel_reference_occurrences_p0_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p10
    ADD CONSTRAINT codeintel_reference_occurrences_p10_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p11
    ADD CONSTRAINT codeintel_reference_occurrences_p11_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p12
    ADD CONSTRAINT codeintel_reference_occurrences_p12_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p13
    ADD CONSTRAINT codeintel_reference_occurrences_p13_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p14
    ADD CONSTRAINT codeintel_reference_occurrences_p14_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p15
    ADD CONSTRAINT codeintel_reference_occurrences_p15_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p16
    ADD CONSTRAINT codeintel_reference_occurrences_p16_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p17
    ADD CONSTRAINT codeintel_reference_occurrences_p17_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p18
    ADD CONSTRAINT codeintel_reference_occurrences_p18_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p19
    ADD CONSTRAINT codeintel_reference_occurrences_p19_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p1
    ADD CONSTRAINT codeintel_reference_occurrences_p1_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p20
    ADD CONSTRAINT codeintel_reference_occurrences_p20_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p21
    ADD CONSTRAINT codeintel_reference_occurrences_p21_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p22
    ADD CONSTRAINT codeintel_reference_occurrences_p22_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p23
    ADD CONSTRAINT codeintel_reference_occurrences_p23_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p24
    ADD CONSTRAINT codeintel_reference_occurrences_p24_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p25
    ADD CONSTRAINT codeintel_reference_occurrences_p25_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p26
    ADD CONSTRAINT codeintel_reference_occurrences_p26_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p27
    ADD CONSTRAINT codeintel_reference_occurrences_p27_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p28
    ADD CONSTRAINT codeintel_reference_occurrences_p28_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p29
    ADD CONSTRAINT codeintel_reference_occurrences_p29_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p2
    ADD CONSTRAINT codeintel_reference_occurrences_p2_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p30
    ADD CONSTRAINT codeintel_reference_occurrences_p30_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p31
    ADD CONSTRAINT codeintel_reference_occurrences_p31_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p32
    ADD CONSTRAINT codeintel_reference_occurrences_p32_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p33
    ADD CONSTRAINT codeintel_reference_occurrences_p33_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p34
    ADD CONSTRAINT codeintel_reference_occurrences_p34_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p35
    ADD CONSTRAINT codeintel_reference_occurrences_p35_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p36
    ADD CONSTRAINT codeintel_reference_occurrences_p36_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p37
    ADD CONSTRAINT codeintel_reference_occurrences_p37_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p38
    ADD CONSTRAINT codeintel_reference_occurrences_p38_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p39
    ADD CONSTRAINT codeintel_reference_occurrences_p39_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p3
    ADD CONSTRAINT codeintel_reference_occurrences_p3_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p40
    ADD CONSTRAINT codeintel_reference_occurrences_p40_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p41
    ADD CONSTRAINT codeintel_reference_occurrences_p41_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p42
    ADD CONSTRAINT codeintel_reference_occurrences_p42_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p43
    ADD CONSTRAINT codeintel_reference_occurrences_p43_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p44
    ADD CONSTRAINT codeintel_reference_occurrences_p44_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p45
    ADD CONSTRAINT codeintel_reference_occurrences_p45_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p46
    ADD CONSTRAINT codeintel_reference_occurrences_p46_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p47
    ADD CONSTRAINT codeintel_reference_occurrences_p47_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p48
    ADD CONSTRAINT codeintel_reference_occurrences_p48_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p49
    ADD CONSTRAINT codeintel_reference_occurrences_p49_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p4
    ADD CONSTRAINT codeintel_reference_occurrences_p4_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p50
    ADD CONSTRAINT codeintel_reference_occurrences_p50_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p51
    ADD CONSTRAINT codeintel_reference_occurrences_p51_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p52
    ADD CONSTRAINT codeintel_reference_occurrences_p52_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p53
    ADD CONSTRAINT codeintel_reference_occurrences_p53_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p54
    ADD CONSTRAINT codeintel_reference_occurrences_p54_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p55
    ADD CONSTRAINT codeintel_reference_occurrences_p55_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p56
    ADD CONSTRAINT codeintel_reference_occurrences_p56_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p57
    ADD CONSTRAINT codeintel_reference_occurrences_p57_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p58
    ADD CONSTRAINT codeintel_reference_occurrences_p58_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p59
    ADD CONSTRAINT codeintel_reference_occurrences_p59_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p5
    ADD CONSTRAINT codeintel_reference_occurrences_p5_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p60
    ADD CONSTRAINT codeintel_reference_occurrences_p60_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p61
    ADD CONSTRAINT codeintel_reference_occurrences_p61_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p62
    ADD CONSTRAINT codeintel_reference_occurrences_p62_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p63
    ADD CONSTRAINT codeintel_reference_occurrences_p63_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p6
    ADD CONSTRAINT codeintel_reference_occurrences_p6_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p7
    ADD CONSTRAINT codeintel_reference_occurrences_p7_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p8
    ADD CONSTRAINT codeintel_reference_occurrences_p8_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_reference_occurrences_p9
    ADD CONSTRAINT codeintel_reference_occurrences_p9_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token);

ALTER TABLE ONLY codeintel_scip_document_lookup
    ADD CONSTRAINT codeintel_scip_document_lookup_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_scip_document_lookup_schema_versions
    ADD CONSTRAINT codeintel_scip_document_lookup_schema_versions_pkey PRIMARY KEY (upload_id);

ALTER TABLE ONLY codeintel_scip_document_lookup
    ADD CONSTRAINT codeintel_scip_document_lookup_upload_id_document_path_key UNIQUE (upload_id, document_path);

ALTER TABLE ONLY codeintel_scip_documents_dereference_logs
    ADD CONSTRAINT codeintel_scip_documents_dereference_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_scip_documents
    ADD CONSTRAINT codeintel_scip_documents_payload_hash_key UNIQUE (payload_hash, tenant_id);

ALTER TABLE ONLY codeintel_scip_documents
    ADD CONSTRAINT codeintel_scip_documents_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_scip_metadata
    ADD CONSTRAINT codeintel_scip_metadata_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_scip_symbol_names
    ADD CONSTRAINT codeintel_scip_symbol_names_pkey PRIMARY KEY (upload_id, id);

ALTER TABLE ONLY codeintel_scip_symbols
    ADD CONSTRAINT codeintel_scip_symbols_pkey PRIMARY KEY (upload_id, symbol_id, document_lookup_id);

ALTER TABLE ONLY codeintel_scip_symbols_schema_versions
    ADD CONSTRAINT codeintel_scip_symbols_schema_versions_pkey PRIMARY KEY (upload_id);

ALTER TABLE ONLY codeintel_scopes
    ADD CONSTRAINT codeintel_scopes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_scopes
    ADD CONSTRAINT codeintel_scopes_tenant_id_hash_key UNIQUE (tenant_id, hash);

ALTER TABLE ONLY codeintel_symbols_p0
    ADD CONSTRAINT codeintel_symbols_p0_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p10
    ADD CONSTRAINT codeintel_symbols_p10_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p11
    ADD CONSTRAINT codeintel_symbols_p11_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p12
    ADD CONSTRAINT codeintel_symbols_p12_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p13
    ADD CONSTRAINT codeintel_symbols_p13_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p14
    ADD CONSTRAINT codeintel_symbols_p14_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p15
    ADD CONSTRAINT codeintel_symbols_p15_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p16
    ADD CONSTRAINT codeintel_symbols_p16_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p17
    ADD CONSTRAINT codeintel_symbols_p17_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p18
    ADD CONSTRAINT codeintel_symbols_p18_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p19
    ADD CONSTRAINT codeintel_symbols_p19_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p1
    ADD CONSTRAINT codeintel_symbols_p1_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p20
    ADD CONSTRAINT codeintel_symbols_p20_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p21
    ADD CONSTRAINT codeintel_symbols_p21_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p22
    ADD CONSTRAINT codeintel_symbols_p22_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p23
    ADD CONSTRAINT codeintel_symbols_p23_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p24
    ADD CONSTRAINT codeintel_symbols_p24_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p25
    ADD CONSTRAINT codeintel_symbols_p25_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p26
    ADD CONSTRAINT codeintel_symbols_p26_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p27
    ADD CONSTRAINT codeintel_symbols_p27_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p28
    ADD CONSTRAINT codeintel_symbols_p28_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p29
    ADD CONSTRAINT codeintel_symbols_p29_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p2
    ADD CONSTRAINT codeintel_symbols_p2_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p30
    ADD CONSTRAINT codeintel_symbols_p30_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p31
    ADD CONSTRAINT codeintel_symbols_p31_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p32
    ADD CONSTRAINT codeintel_symbols_p32_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p33
    ADD CONSTRAINT codeintel_symbols_p33_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p34
    ADD CONSTRAINT codeintel_symbols_p34_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p35
    ADD CONSTRAINT codeintel_symbols_p35_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p36
    ADD CONSTRAINT codeintel_symbols_p36_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p37
    ADD CONSTRAINT codeintel_symbols_p37_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p38
    ADD CONSTRAINT codeintel_symbols_p38_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p39
    ADD CONSTRAINT codeintel_symbols_p39_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p3
    ADD CONSTRAINT codeintel_symbols_p3_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p40
    ADD CONSTRAINT codeintel_symbols_p40_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p41
    ADD CONSTRAINT codeintel_symbols_p41_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p42
    ADD CONSTRAINT codeintel_symbols_p42_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p43
    ADD CONSTRAINT codeintel_symbols_p43_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p44
    ADD CONSTRAINT codeintel_symbols_p44_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p45
    ADD CONSTRAINT codeintel_symbols_p45_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p46
    ADD CONSTRAINT codeintel_symbols_p46_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p47
    ADD CONSTRAINT codeintel_symbols_p47_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p48
    ADD CONSTRAINT codeintel_symbols_p48_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p49
    ADD CONSTRAINT codeintel_symbols_p49_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p4
    ADD CONSTRAINT codeintel_symbols_p4_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p50
    ADD CONSTRAINT codeintel_symbols_p50_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p51
    ADD CONSTRAINT codeintel_symbols_p51_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p52
    ADD CONSTRAINT codeintel_symbols_p52_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p53
    ADD CONSTRAINT codeintel_symbols_p53_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p54
    ADD CONSTRAINT codeintel_symbols_p54_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p55
    ADD CONSTRAINT codeintel_symbols_p55_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p56
    ADD CONSTRAINT codeintel_symbols_p56_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p57
    ADD CONSTRAINT codeintel_symbols_p57_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p58
    ADD CONSTRAINT codeintel_symbols_p58_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p59
    ADD CONSTRAINT codeintel_symbols_p59_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p5
    ADD CONSTRAINT codeintel_symbols_p5_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p60
    ADD CONSTRAINT codeintel_symbols_p60_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p61
    ADD CONSTRAINT codeintel_symbols_p61_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p62
    ADD CONSTRAINT codeintel_symbols_p62_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p63
    ADD CONSTRAINT codeintel_symbols_p63_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p6
    ADD CONSTRAINT codeintel_symbols_p6_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p7
    ADD CONSTRAINT codeintel_symbols_p7_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p8
    ADD CONSTRAINT codeintel_symbols_p8_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_symbols_p9
    ADD CONSTRAINT codeintel_symbols_p9_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id);

ALTER TABLE ONLY codeintel_writer_control
    ADD CONSTRAINT codeintel_writer_control_pkey PRIMARY KEY (tenant_id);

ALTER TABLE ONLY rockskip_ancestry
    ADD CONSTRAINT rockskip_ancestry_pkey PRIMARY KEY (id);

ALTER TABLE ONLY rockskip_ancestry
    ADD CONSTRAINT rockskip_ancestry_repo_id_commit_id_key UNIQUE (repo_id, commit_id);

ALTER TABLE ONLY rockskip_repos
    ADD CONSTRAINT rockskip_repos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY rockskip_repos
    ADD CONSTRAINT rockskip_repos_repo_key UNIQUE (repo, tenant_id);

ALTER TABLE ONLY rockskip_symbols
    ADD CONSTRAINT rockskip_symbols_pkey PRIMARY KEY (id);

ALTER TABLE ONLY tenants
    ADD CONSTRAINT tenants_name_key UNIQUE (name);

ALTER TABLE ONLY tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);

ALTER TABLE ONLY tenants
    ADD CONSTRAINT tenants_workspace_id_key UNIQUE (workspace_id);

CREATE INDEX codeintel_document_manifest_chunks_tenant_id ON codeintel_document_manifest_chunks USING btree (tenant_id) WHERE (tenant_id <> 1);

CREATE INDEX codeintel_document_manifests_essential ON codeintel_document_manifests USING btree (essential_manifest_id);

CREATE INDEX codeintel_documents_p0_order_key ON codeintel_documents_p0 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_tenant_id_id ON ONLY codeintel_documents USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p0_tenant_id_id_idx ON codeintel_documents_p0 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p10_order_key ON codeintel_documents_p10 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p10_tenant_id_id_idx ON codeintel_documents_p10 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p11_order_key ON codeintel_documents_p11 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p11_tenant_id_id_idx ON codeintel_documents_p11 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p12_order_key ON codeintel_documents_p12 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p12_tenant_id_id_idx ON codeintel_documents_p12 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p13_order_key ON codeintel_documents_p13 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p13_tenant_id_id_idx ON codeintel_documents_p13 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p14_order_key ON codeintel_documents_p14 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p14_tenant_id_id_idx ON codeintel_documents_p14 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p15_order_key ON codeintel_documents_p15 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p15_tenant_id_id_idx ON codeintel_documents_p15 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p1_order_key ON codeintel_documents_p1 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p1_tenant_id_id_idx ON codeintel_documents_p1 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p2_order_key ON codeintel_documents_p2 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p2_tenant_id_id_idx ON codeintel_documents_p2 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p3_order_key ON codeintel_documents_p3 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p3_tenant_id_id_idx ON codeintel_documents_p3 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p4_order_key ON codeintel_documents_p4 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p4_tenant_id_id_idx ON codeintel_documents_p4 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p5_order_key ON codeintel_documents_p5 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p5_tenant_id_id_idx ON codeintel_documents_p5 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p6_order_key ON codeintel_documents_p6 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p6_tenant_id_id_idx ON codeintel_documents_p6 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p7_order_key ON codeintel_documents_p7 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p7_tenant_id_id_idx ON codeintel_documents_p7 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p8_order_key ON codeintel_documents_p8 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p8_tenant_id_id_idx ON codeintel_documents_p8 USING btree (tenant_id, id);

CREATE INDEX codeintel_documents_p9_order_key ON codeintel_documents_p9 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_documents_p9_tenant_id_id_idx ON codeintel_documents_p9 USING btree (tenant_id, id);

CREATE INDEX codeintel_essential_manifest_chunks_tenant_id ON codeintel_essential_manifest_chunks USING btree (tenant_id) WHERE (tenant_id <> 1);

CREATE INDEX codeintel_essential_manifests_scope ON codeintel_essential_manifests USING btree (scope_id);

CREATE INDEX codeintel_essentials_p0_order_key ON codeintel_essentials_p0 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_tenant_id_id ON ONLY codeintel_essentials USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p0_tenant_id_id_idx ON codeintel_essentials_p0 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p10_order_key ON codeintel_essentials_p10 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p10_tenant_id_id_idx ON codeintel_essentials_p10 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p11_order_key ON codeintel_essentials_p11 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p11_tenant_id_id_idx ON codeintel_essentials_p11 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p12_order_key ON codeintel_essentials_p12 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p12_tenant_id_id_idx ON codeintel_essentials_p12 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p13_order_key ON codeintel_essentials_p13 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p13_tenant_id_id_idx ON codeintel_essentials_p13 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p14_order_key ON codeintel_essentials_p14 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p14_tenant_id_id_idx ON codeintel_essentials_p14 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p15_order_key ON codeintel_essentials_p15 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p15_tenant_id_id_idx ON codeintel_essentials_p15 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p1_order_key ON codeintel_essentials_p1 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p1_tenant_id_id_idx ON codeintel_essentials_p1 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p2_order_key ON codeintel_essentials_p2 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p2_tenant_id_id_idx ON codeintel_essentials_p2 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p3_order_key ON codeintel_essentials_p3 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p3_tenant_id_id_idx ON codeintel_essentials_p3 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p4_order_key ON codeintel_essentials_p4 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p4_tenant_id_id_idx ON codeintel_essentials_p4 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p5_order_key ON codeintel_essentials_p5 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p5_tenant_id_id_idx ON codeintel_essentials_p5 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p6_order_key ON codeintel_essentials_p6 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p6_tenant_id_id_idx ON codeintel_essentials_p6 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p7_order_key ON codeintel_essentials_p7 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p7_tenant_id_id_idx ON codeintel_essentials_p7 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p8_order_key ON codeintel_essentials_p8 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p8_tenant_id_id_idx ON codeintel_essentials_p8 USING btree (tenant_id, id);

CREATE INDEX codeintel_essentials_p9_order_key ON codeintel_essentials_p9 USING btree (tenant_id, order_key, id);

CREATE INDEX codeintel_essentials_p9_tenant_id_id_idx ON codeintel_essentials_p9 USING btree (tenant_id, id);

CREATE INDEX codeintel_index_external_ids_index ON codeintel_index_external_ids USING btree (index_id);

CREATE INDEX codeintel_index_package_version_essential_chunks_tenant_id ON codeintel_index_package_version_essential_chunks USING btree (tenant_id) WHERE (tenant_id <> 1);

CREATE INDEX codeintel_indexes_pending ON codeintel_indexes USING btree (tenant_id) WHERE (state = 'pending'::text);

CREATE INDEX codeintel_indexes_tenant_id ON codeintel_indexes USING btree (tenant_id) WHERE (tenant_id <> 1);

CREATE INDEX codeintel_last_reconcile_last_reconcile_at_dump_id ON codeintel_last_reconcile USING btree (last_reconcile_at, dump_id);

CREATE INDEX codeintel_scip_document_lookup_document_id ON codeintel_scip_document_lookup USING hash (document_id);

CREATE INDEX codeintel_scip_document_lookup_tenant_id ON codeintel_scip_document_lookup USING btree (tenant_id) WHERE (tenant_id <> 1);

CREATE INDEX codeintel_scip_documents_dereference_logs_last_removal_time_des ON codeintel_scip_documents_dereference_logs USING btree (last_removal_time DESC, document_id);

CREATE INDEX codeintel_scip_metadata_upload_id ON codeintel_scip_metadata USING btree (upload_id);

CREATE INDEX codeintel_scip_symbol_names_upload_id_roots ON codeintel_scip_symbol_names USING btree (upload_id) WHERE (prefix_id IS NULL);

CREATE INDEX codeintel_scip_symbols_document_lookup_id ON codeintel_scip_symbols USING btree (document_lookup_id);

CREATE INDEX codeintel_symbols_p0_tenant_id_id ON codeintel_symbols_p0 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p10_tenant_id_id ON codeintel_symbols_p10 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p11_tenant_id_id ON codeintel_symbols_p11 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p12_tenant_id_id ON codeintel_symbols_p12 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p13_tenant_id_id ON codeintel_symbols_p13 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p14_tenant_id_id ON codeintel_symbols_p14 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p15_tenant_id_id ON codeintel_symbols_p15 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p16_tenant_id_id ON codeintel_symbols_p16 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p17_tenant_id_id ON codeintel_symbols_p17 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p18_tenant_id_id ON codeintel_symbols_p18 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p19_tenant_id_id ON codeintel_symbols_p19 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p1_tenant_id_id ON codeintel_symbols_p1 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p20_tenant_id_id ON codeintel_symbols_p20 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p21_tenant_id_id ON codeintel_symbols_p21 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p22_tenant_id_id ON codeintel_symbols_p22 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p23_tenant_id_id ON codeintel_symbols_p23 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p24_tenant_id_id ON codeintel_symbols_p24 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p25_tenant_id_id ON codeintel_symbols_p25 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p26_tenant_id_id ON codeintel_symbols_p26 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p27_tenant_id_id ON codeintel_symbols_p27 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p28_tenant_id_id ON codeintel_symbols_p28 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p29_tenant_id_id ON codeintel_symbols_p29 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p2_tenant_id_id ON codeintel_symbols_p2 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p30_tenant_id_id ON codeintel_symbols_p30 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p31_tenant_id_id ON codeintel_symbols_p31 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p32_tenant_id_id ON codeintel_symbols_p32 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p33_tenant_id_id ON codeintel_symbols_p33 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p34_tenant_id_id ON codeintel_symbols_p34 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p35_tenant_id_id ON codeintel_symbols_p35 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p36_tenant_id_id ON codeintel_symbols_p36 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p37_tenant_id_id ON codeintel_symbols_p37 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p38_tenant_id_id ON codeintel_symbols_p38 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p39_tenant_id_id ON codeintel_symbols_p39 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p3_tenant_id_id ON codeintel_symbols_p3 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p40_tenant_id_id ON codeintel_symbols_p40 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p41_tenant_id_id ON codeintel_symbols_p41 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p42_tenant_id_id ON codeintel_symbols_p42 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p43_tenant_id_id ON codeintel_symbols_p43 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p44_tenant_id_id ON codeintel_symbols_p44 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p45_tenant_id_id ON codeintel_symbols_p45 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p46_tenant_id_id ON codeintel_symbols_p46 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p47_tenant_id_id ON codeintel_symbols_p47 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p48_tenant_id_id ON codeintel_symbols_p48 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p49_tenant_id_id ON codeintel_symbols_p49 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p4_tenant_id_id ON codeintel_symbols_p4 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p50_tenant_id_id ON codeintel_symbols_p50 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p51_tenant_id_id ON codeintel_symbols_p51 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p52_tenant_id_id ON codeintel_symbols_p52 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p53_tenant_id_id ON codeintel_symbols_p53 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p54_tenant_id_id ON codeintel_symbols_p54 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p55_tenant_id_id ON codeintel_symbols_p55 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p56_tenant_id_id ON codeintel_symbols_p56 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p57_tenant_id_id ON codeintel_symbols_p57 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p58_tenant_id_id ON codeintel_symbols_p58 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p59_tenant_id_id ON codeintel_symbols_p59 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p5_tenant_id_id ON codeintel_symbols_p5 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p60_tenant_id_id ON codeintel_symbols_p60 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p61_tenant_id_id ON codeintel_symbols_p61 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p62_tenant_id_id ON codeintel_symbols_p62 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p63_tenant_id_id ON codeintel_symbols_p63 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p6_tenant_id_id ON codeintel_symbols_p6 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p7_tenant_id_id ON codeintel_symbols_p7 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p8_tenant_id_id ON codeintel_symbols_p8 USING btree (tenant_id, id);

CREATE INDEX codeintel_symbols_p9_tenant_id_id ON codeintel_symbols_p9 USING btree (tenant_id, id);

CREATE INDEX codeisdntel_scip_symbol_names_upload_id_children ON codeintel_scip_symbol_names USING btree (upload_id, prefix_id) WHERE (prefix_id IS NOT NULL);

CREATE INDEX rockskip_repos_last_accessed_at ON rockskip_repos USING btree (last_accessed_at);

CREATE INDEX rockskip_symbols_gin ON rockskip_symbols USING gin (singleton_integer(repo_id) gin__int_ops, added gin__int_ops, deleted gin__int_ops, name gin_trgm_ops, singleton(name), singleton(lower(name)), path gin_trgm_ops, singleton(path), path_prefixes(path), singleton(lower(path)), path_prefixes(lower(path)), singleton(get_file_extension(path)), singleton(get_file_extension(lower(path))));

CREATE INDEX rockskip_symbols_repo_id_path_name ON rockskip_symbols USING btree (repo_id, path, name);

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p0_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p0_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p10_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p10_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p11_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p11_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p12_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p12_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p13_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p13_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p14_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p14_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p15_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p15_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p1_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p1_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p2_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p2_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p3_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p3_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p4_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p4_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p5_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p5_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p6_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p6_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p7_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p7_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p8_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p8_tenant_id_id_idx;

ALTER INDEX codeintel_documents_pkey ATTACH PARTITION codeintel_documents_p9_pkey;

ALTER INDEX codeintel_documents_tenant_id_id ATTACH PARTITION codeintel_documents_p9_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p0_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p0_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p10_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p10_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p11_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p11_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p12_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p12_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p13_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p13_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p14_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p14_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p15_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p15_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p1_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p1_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p2_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p2_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p3_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p3_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p4_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p4_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p5_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p5_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p6_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p6_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p7_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p7_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p8_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p8_tenant_id_id_idx;

ALTER INDEX codeintel_essentials_pkey ATTACH PARTITION codeintel_essentials_p9_pkey;

ALTER INDEX codeintel_essentials_tenant_id_id ATTACH PARTITION codeintel_essentials_p9_tenant_id_id_idx;

CREATE TRIGGER codeintel_scip_document_lookup_schema_versions_insert AFTER INSERT ON codeintel_scip_document_lookup REFERENCING NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION update_codeintel_scip_document_lookup_schema_versions_insert();

CREATE TRIGGER codeintel_scip_documents_dereference_logs_insert AFTER DELETE ON codeintel_scip_document_lookup REFERENCING OLD TABLE AS oldtab FOR EACH STATEMENT EXECUTE FUNCTION update_codeintel_scip_documents_dereference_logs_delete();

CREATE TRIGGER codeintel_scip_symbols_schema_versions_insert AFTER INSERT ON codeintel_scip_symbols REFERENCING NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION update_codeintel_scip_symbols_schema_versions_insert();

ALTER TABLE ONLY codeintel_document_manifest_chunks
    ADD CONSTRAINT codeintel_document_manifest_chunks_document_manifest_id_fkey FOREIGN KEY (document_manifest_id) REFERENCES codeintel_document_manifests(id) ON DELETE CASCADE;

ALTER TABLE ONLY codeintel_document_manifests
    ADD CONSTRAINT codeintel_document_manifests_essential_manifest_id_fkey FOREIGN KEY (essential_manifest_id) REFERENCES codeintel_essential_manifests(id);

ALTER TABLE ONLY codeintel_document_path_chunks_p0
    ADD CONSTRAINT codeintel_document_path_chunks_p0_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p10
    ADD CONSTRAINT codeintel_document_path_chunks_p10_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p11
    ADD CONSTRAINT codeintel_document_path_chunks_p11_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p12
    ADD CONSTRAINT codeintel_document_path_chunks_p12_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p13
    ADD CONSTRAINT codeintel_document_path_chunks_p13_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p14
    ADD CONSTRAINT codeintel_document_path_chunks_p14_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p15
    ADD CONSTRAINT codeintel_document_path_chunks_p15_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p1
    ADD CONSTRAINT codeintel_document_path_chunks_p1_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p2
    ADD CONSTRAINT codeintel_document_path_chunks_p2_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p3
    ADD CONSTRAINT codeintel_document_path_chunks_p3_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p4
    ADD CONSTRAINT codeintel_document_path_chunks_p4_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p5
    ADD CONSTRAINT codeintel_document_path_chunks_p5_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p6
    ADD CONSTRAINT codeintel_document_path_chunks_p6_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p7
    ADD CONSTRAINT codeintel_document_path_chunks_p7_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p8
    ADD CONSTRAINT codeintel_document_path_chunks_p8_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_document_path_chunks_p9
    ADD CONSTRAINT codeintel_document_path_chunks_p9_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE codeintel_documents
    ADD CONSTRAINT codeintel_documents_tenant_id_order_key_fkey FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_essential_manifest_chunks
    ADD CONSTRAINT codeintel_essential_manifest_chunks_essential_manifest_id_fkey FOREIGN KEY (essential_manifest_id) REFERENCES codeintel_essential_manifests(id) ON DELETE CASCADE;

ALTER TABLE codeintel_essentials
    ADD CONSTRAINT codeintel_essentials_tenant_id_order_key_fkey FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key);

ALTER TABLE ONLY codeintel_index_external_ids
    ADD CONSTRAINT codeintel_index_external_ids_index_id_fkey FOREIGN KEY (index_id) REFERENCES codeintel_indexes(id);

ALTER TABLE ONLY codeintel_index_package_version_essential_chunks
    ADD CONSTRAINT codeintel_index_package_version_essential_chunks_version_fkey FOREIGN KEY (index_package_version_id) REFERENCES codeintel_index_package_versions(id) ON DELETE CASCADE;

ALTER TABLE ONLY codeintel_index_package_versions
    ADD CONSTRAINT codeintel_index_package_versions_package_id_fkey FOREIGN KEY (package_id) REFERENCES codeintel_packages(id);

ALTER TABLE ONLY codeintel_indexes
    ADD CONSTRAINT codeintel_indexes_document_manifest_id_fkey FOREIGN KEY (document_manifest_id) REFERENCES codeintel_document_manifests(id);

ALTER TABLE ONLY codeintel_scip_document_lookup
    ADD CONSTRAINT codeintel_scip_document_lookup_document_id_fk FOREIGN KEY (document_id) REFERENCES codeintel_scip_documents(id);

ALTER TABLE ONLY codeintel_scip_symbols
    ADD CONSTRAINT codeintel_scip_symbols_document_lookup_id_fk FOREIGN KEY (document_lookup_id) REFERENCES codeintel_scip_document_lookup(id) ON DELETE CASCADE;

ALTER TABLE codeintel_definition_occurrences_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p16 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p17 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p18 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p19 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p20 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p21 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p22 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p23 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p24 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p25 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p26 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p27 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p28 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p29 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p30 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p31 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p32 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p33 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p34 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p35 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p36 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p37 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p38 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p39 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p40 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p41 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p42 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p43 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p44 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p45 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p46 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p47 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p48 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p49 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p50 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p51 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p52 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p53 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p54 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p55 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p56 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p57 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p58 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p59 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p60 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p61 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p62 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p63 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_definition_occurrences_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_manifest_chunks ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_manifests ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_path_chunks_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_paths ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_document_payloads_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_documents_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_manifest_chunks ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_manifests ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essential_symbol_chunks_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_essentials_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p16 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p17 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p18 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p19 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p20 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p21 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p22 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p23 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p24 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p25 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p26 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p27 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p28 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p29 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p30 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p31 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p32 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p33 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p34 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p35 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p36 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p37 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p38 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p39 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p40 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p41 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p42 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p43 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p44 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p45 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p46 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p47 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p48 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p49 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p50 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p51 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p52 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p53 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p54 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p55 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p56 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p57 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p58 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p59 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p60 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p61 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p62 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p63 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_implementation_occurrences_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_index_external_ids ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_index_package_version_essential_chunks ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_index_package_versions ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_indexes ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_last_reconcile ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_packages ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p16 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p17 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p18 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p19 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p20 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p21 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p22 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p23 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p24 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p25 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p26 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p27 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p28 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p29 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p30 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p31 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p32 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p33 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p34 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p35 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p36 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p37 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p38 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p39 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p40 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p41 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p42 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p43 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p44 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p45 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p46 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p47 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p48 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p49 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p50 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p51 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p52 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p53 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p54 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p55 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p56 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p57 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p58 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p59 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p60 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p61 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p62 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p63 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_reference_occurrences_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scip_document_lookup ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scip_document_lookup_schema_versions ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scip_documents ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scip_documents_dereference_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scip_metadata ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scip_symbol_names ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scip_symbols ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scip_symbols_schema_versions ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_scopes ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p0 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p1 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p10 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p11 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p12 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p13 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p14 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p15 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p16 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p17 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p18 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p19 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p2 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p20 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p21 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p22 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p23 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p24 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p25 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p26 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p27 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p28 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p29 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p3 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p30 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p31 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p32 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p33 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p34 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p35 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p36 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p37 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p38 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p39 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p4 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p40 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p41 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p42 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p43 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p44 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p45 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p46 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p47 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p48 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p49 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p5 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p50 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p51 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p52 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p53 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p54 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p55 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p56 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p57 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p58 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p59 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p6 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p60 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p61 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p62 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p63 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p7 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p8 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_symbols_p9 ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_writer_control ENABLE ROW LEVEL SECURITY;

ALTER TABLE rockskip_ancestry ENABLE ROW LEVEL SECURITY;

ALTER TABLE rockskip_repos ENABLE ROW LEVEL SECURITY;

ALTER TABLE rockskip_symbols ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p16 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p17 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p18 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p19 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p20 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p21 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p22 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p23 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p24 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p25 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p26 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p27 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p28 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p29 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p30 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p31 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p32 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p33 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p34 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p35 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p36 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p37 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p38 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p39 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p40 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p41 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p42 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p43 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p44 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p45 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p46 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p47 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p48 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p49 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p50 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p51 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p52 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p53 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p54 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p55 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p56 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p57 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p58 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p59 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p60 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p61 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p62 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p63 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_definition_occurrences_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_manifest_chunks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_manifests USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_path_chunks_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_paths USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_document_payloads_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_documents_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_manifest_chunks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_manifests USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essential_symbol_chunks_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_essentials_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p16 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p17 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p18 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p19 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p20 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p21 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p22 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p23 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p24 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p25 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p26 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p27 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p28 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p29 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p30 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p31 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p32 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p33 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p34 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p35 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p36 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p37 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p38 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p39 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p40 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p41 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p42 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p43 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p44 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p45 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p46 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p47 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p48 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p49 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p50 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p51 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p52 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p53 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p54 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p55 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p56 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p57 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p58 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p59 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p60 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p61 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p62 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p63 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_implementation_occurrences_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_index_external_ids USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_index_package_version_essential_chunks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_index_package_versions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_indexes USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_last_reconcile USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_packages USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p16 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p17 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p18 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p19 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p20 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p21 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p22 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p23 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p24 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p25 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p26 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p27 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p28 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p29 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p30 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p31 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p32 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p33 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p34 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p35 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p36 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p37 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p38 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p39 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p40 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p41 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p42 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p43 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p44 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p45 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p46 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p47 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p48 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p49 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p50 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p51 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p52 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p53 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p54 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p55 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p56 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p57 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p58 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p59 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p60 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p61 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p62 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p63 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_reference_occurrences_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scip_document_lookup USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scip_document_lookup_schema_versions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scip_documents USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scip_documents_dereference_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scip_metadata USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scip_symbol_names USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scip_symbols USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scip_symbols_schema_versions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_scopes USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p0 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p1 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p10 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p11 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p12 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p13 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p14 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p15 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p16 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p17 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p18 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p19 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p2 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p20 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p21 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p22 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p23 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p24 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p25 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p26 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p27 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p28 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p29 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p3 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p30 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p31 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p32 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p33 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p34 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p35 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p36 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p37 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p38 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p39 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p4 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p40 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p41 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p42 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p43 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p44 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p45 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p46 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p47 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p48 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p49 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p5 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p50 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p51 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p52 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p53 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p54 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p55 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p56 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p57 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p58 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p59 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p6 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p60 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p61 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p62 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p63 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p7 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p8 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_symbols_p9 USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_writer_control USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON rockskip_ancestry USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON rockskip_repos USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON rockskip_symbols USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON tenants USING ((( SELECT (current_setting('app.current_tenant'::text) = ANY (ARRAY['servicetenant'::text, 'workertenant'::text, 'zoekttenant'::text]))) OR (id = ( SELECT (NULLIF(NULLIF(NULLIF(current_setting('app.current_tenant'::text), 'servicetenant'::text), 'workertenant'::text), 'zoekttenant'::text))::integer AS current_tenant))));

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

INSERT INTO tenants (id, name, workspace_id, display_name, state, external_url, redis_pruned_at, deleted_at, gitserver_pruned_at, zoekt_pruned_at, blobstore_pruned_at, database_pruned_at, searcher_cache_pruned_at) VALUES (1, 'default', '6a6b043c-ffed-42ec-b1f4-abc231cd7222', NULL, 'active', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL);

SELECT pg_catalog.setval('tenants_id_seq', 1, true);
