-- Bitmap columns are bytea holding the portable Roaring serialization of one
-- 2^32-wide bucket of 64-bit IDs. The writer and the reader run every set
-- operation in Go, so no PostgreSQL extension is required. Bitmaps are
-- already compact, so they are stored out of line without compression.

-- Per-partition sequences from which the writer allocates document, essential,
-- and symbol IDs.
DO $$
DECLARE
    i integer;
    first integer;
BEGIN
    FOR i IN 0..15 LOOP
        first := CASE WHEN i = 0 THEN 1 ELSE 0 END;
        EXECUTE format('CREATE SEQUENCE IF NOT EXISTS codeintel_document_id_seq_p%1$s AS bigint MINVALUE %2$s MAXVALUE 576460752303423487 START WITH %2$s NO CYCLE', i, first);
        EXECUTE format('CREATE SEQUENCE IF NOT EXISTS codeintel_essential_id_seq_p%1$s AS bigint MINVALUE %2$s MAXVALUE 576460752303423487 START WITH %2$s NO CYCLE', i, first);
    END LOOP;
    FOR i IN 0..63 LOOP
        first := CASE WHEN i = 0 THEN 1 ELSE 0 END;
        EXECUTE format('CREATE SEQUENCE IF NOT EXISTS codeintel_symbol_id_seq_p%1$s AS bigint MINVALUE %2$s MAXVALUE 144115188075855871 START WITH %2$s NO CYCLE', i, first);
    END LOOP;
END $$;

-- Every row belongs to one tenant. Every key that is not anchored to a serial
-- ID includes tenant_id, so no two tenants share a row.

-- A path lives while a path chunk (below) lists one of its documents; cleanup
-- deletes it with its last chunk. Essentials and postings of a live essential
-- always share the path of a live document of the same scope.
CREATE TABLE IF NOT EXISTS codeintel_document_paths (
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    relative_path text COLLATE "C" NOT NULL,
    order_key bytea NOT NULL CHECK (octet_length(order_key) BETWEEN 1 AND 1024),
    PRIMARY KEY (tenant_id, relative_path),
    UNIQUE (tenant_id, order_key)
) WITH (fillfactor = 70);

CREATE TABLE IF NOT EXISTS codeintel_documents (
    id bigint NOT NULL,
    essential_id bigint NOT NULL,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    hash bytea NOT NULL CHECK (octet_length(hash) = 32),
    order_key bytea NOT NULL,
    PRIMARY KEY (tenant_id, hash) INCLUDE (id),
    FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key)
) PARTITION BY RANGE (hash);

CREATE TABLE IF NOT EXISTS codeintel_essentials (
    id bigint NOT NULL,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    hash bytea NOT NULL CHECK (octet_length(hash) = 32),
    order_key bytea NOT NULL,
    PRIMARY KEY (tenant_id, hash) INCLUDE (id),
    FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key)
) PARTITION BY RANGE (hash);

-- One row per (tenant, repository, exact root, indexer). There is
-- intentionally no reference count or foreign key: cleanup removes a scope
-- once no essential manifest references it.
CREATE TABLE IF NOT EXISTS codeintel_scopes (
    id serial PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    repository_id bigint NOT NULL CHECK (repository_id > 0),
    hash bytea NOT NULL CHECK (octet_length(hash) = 32),
    root text NOT NULL,
    indexer text NOT NULL,
    UNIQUE (tenant_id, hash)
);

-- Fences each tenant's writer: each claim increments owner_epoch, and every
-- write transaction checks it under FOR SHARE. A writer creates its tenant's
-- row on first claim.
CREATE TABLE IF NOT EXISTS codeintel_writer_control (
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0) PRIMARY KEY,
    owner_epoch bigint NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS codeintel_essential_manifests (
    id bigserial PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    essential_count integer NOT NULL,
    scope_id integer NOT NULL,
    hash bytea NOT NULL CHECK (octet_length(hash) = 32),
    UNIQUE (tenant_id, hash)
);
CREATE INDEX IF NOT EXISTS codeintel_essential_manifests_scope ON codeintel_essential_manifests(scope_id);

CREATE TABLE IF NOT EXISTS codeintel_essential_manifest_chunks (
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    essential_manifest_id bigint NOT NULL REFERENCES codeintel_essential_manifests(id) ON DELETE CASCADE,
    bucket integer NOT NULL CHECK (bucket >= 0),
    bitmap bytea NOT NULL,
    PRIMARY KEY (essential_manifest_id, bucket)
);
ALTER TABLE codeintel_essential_manifest_chunks ALTER COLUMN bitmap SET STORAGE EXTERNAL;

CREATE TABLE IF NOT EXISTS codeintel_document_manifests (
    id bigserial PRIMARY KEY,
    essential_manifest_id bigint NOT NULL REFERENCES codeintel_essential_manifests(id),
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    document_count integer NOT NULL,
    hash bytea NOT NULL CHECK (octet_length(hash) = 32),
    UNIQUE (tenant_id, hash)
);
CREATE INDEX IF NOT EXISTS codeintel_document_manifests_essential ON codeintel_document_manifests(essential_manifest_id);

CREATE TABLE IF NOT EXISTS codeintel_document_manifest_chunks (
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    document_manifest_id bigint NOT NULL REFERENCES codeintel_document_manifests(id) ON DELETE CASCADE,
    bucket integer NOT NULL CHECK (bucket >= 0),
    bitmap bytea NOT NULL,
    PRIMARY KEY (document_manifest_id, bucket)
);
ALTER TABLE codeintel_document_manifest_chunks ALTER COLUMN bitmap SET STORAGE EXTERNAL;

-- An index is identified by its content: two uploads with the same document
-- manifest and package versions are the same index. Uploads attach through
-- codeintel_index_external_ids.
CREATE TABLE IF NOT EXISTS codeintel_indexes (
    id bigserial PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    document_manifest_id bigint NOT NULL REFERENCES codeintel_document_manifests(id),
    package_versions_hash bytea NOT NULL CHECK (octet_length(package_versions_hash) = 32),
    package_versions bytea NOT NULL,
    state text NOT NULL CHECK (state IN ('pending', 'completed')),
    CONSTRAINT codeintel_indexes_manifest_versions_key UNIQUE (document_manifest_id, package_versions_hash)
);
ALTER TABLE codeintel_indexes ALTER COLUMN package_versions SET STORAGE EXTERNAL;

-- Upload IDs are unique only within a tenant.
CREATE TABLE IF NOT EXISTS codeintel_index_external_ids (
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    external_id bigint NOT NULL CHECK (external_id > 0),
    index_id bigint NOT NULL REFERENCES codeintel_indexes(id),
    PRIMARY KEY (tenant_id, external_id)
);
CREATE INDEX IF NOT EXISTS codeintel_index_external_ids_index ON codeintel_index_external_ids(index_id);

CREATE TABLE IF NOT EXISTS codeintel_packages (
    id serial PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    scheme text NOT NULL,
    manager text NOT NULL,
    name text NOT NULL,
    UNIQUE (tenant_id, scheme, manager, name)
);

CREATE TABLE IF NOT EXISTS codeintel_index_package_versions (
    id serial PRIMARY KEY,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer CHECK (tenant_id > 0),
    package_id integer NOT NULL REFERENCES codeintel_packages(id),
    essential_count integer NOT NULL CHECK (essential_count >= 0),
    token smallint NOT NULL,
    hash bytea NOT NULL CHECK (octet_length(hash) = 32),
    value text NOT NULL,
    UNIQUE (tenant_id, hash)
);

CREATE TABLE IF NOT EXISTS codeintel_index_package_version_essential_chunks (
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer
        CONSTRAINT codeintel_index_package_version_essential_chunks_tenant_check CHECK (tenant_id > 0),
    index_package_version_id integer NOT NULL,
    bucket integer NOT NULL CHECK (bucket >= 0),
    bitmap bytea NOT NULL,
    PRIMARY KEY (index_package_version_id, bucket),
    CONSTRAINT codeintel_index_package_version_essential_chunks_version_fkey
        FOREIGN KEY (index_package_version_id) REFERENCES codeintel_index_package_versions(id) ON DELETE CASCADE
);
ALTER TABLE codeintel_index_package_version_essential_chunks ALTER COLUMN bitmap SET STORAGE EXTERNAL;

-- Tables with no key that includes tenant_id get a tenant index that stays
-- empty on single-tenant instances.
CREATE INDEX IF NOT EXISTS codeintel_essential_manifest_chunks_tenant_id ON codeintel_essential_manifest_chunks(tenant_id) WHERE tenant_id <> 1;
CREATE INDEX IF NOT EXISTS codeintel_document_manifest_chunks_tenant_id ON codeintel_document_manifest_chunks(tenant_id) WHERE tenant_id <> 1;
CREATE INDEX IF NOT EXISTS codeintel_indexes_tenant_id ON codeintel_indexes(tenant_id) WHERE tenant_id <> 1;
CREATE INDEX IF NOT EXISTS codeintel_index_package_version_essential_chunks_tenant_id ON codeintel_index_package_version_essential_chunks(tenant_id) WHERE tenant_id <> 1;

-- Row level security is not inherited by partitions, so every table,
-- including each partition, gets its own policy.
CREATE OR REPLACE FUNCTION pg_temp.codeintel_isolate_tenant(t text) RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_policy ON %I', t);
    EXECUTE format('CREATE POLICY tenant_isolation_policy ON %I AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = (SELECT current_setting(''app.current_tenant'')::integer AS current_tenant))', t);
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    PERFORM pg_temp.codeintel_isolate_tenant(t) FROM unnest(ARRAY[
        'codeintel_document_paths',
        'codeintel_documents',
        'codeintel_essentials',
        'codeintel_scopes',
        'codeintel_writer_control',
        'codeintel_essential_manifests',
        'codeintel_essential_manifest_chunks',
        'codeintel_document_manifests',
        'codeintel_document_manifest_chunks',
        'codeintel_indexes',
        'codeintel_index_external_ids',
        'codeintel_packages',
        'codeintel_index_package_versions',
        'codeintel_index_package_version_essential_chunks'
    ]) AS t;
END $$;

-- Creating all 334 tables in one transaction takes about 3,000 locks, which
-- can exhaust the default shared lock table. Commit between table groups.
COMMIT AND CHAIN;

-- Hash-range partitions.
DO $$
DECLARE
    i integer;
    lo text;
    hi text;
BEGIN
    FOR i IN 0..15 LOOP
        lo := format('decode(%L, ''hex'')', encode(set_byte('\x00'::bytea, 0, i * 16), 'hex'));
        hi := CASE WHEN i = 15 THEN 'MAXVALUE' ELSE format('decode(%L, ''hex'')', encode(set_byte('\x00'::bytea, 0, (i + 1) * 16), 'hex')) END;
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_documents_p%s PARTITION OF codeintel_documents FOR VALUES FROM (%s) TO (%s)', i, lo, hi);
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_essentials_p%s PARTITION OF codeintel_essentials FOR VALUES FROM (%s) TO (%s)', i, lo, hi);
        EXECUTE format('CREATE INDEX IF NOT EXISTS codeintel_documents_p%1$s_order_key ON codeintel_documents_p%1$s(tenant_id, order_key, id)', i);
        EXECUTE format('CREATE INDEX IF NOT EXISTS codeintel_essentials_p%1$s_order_key ON codeintel_essentials_p%1$s(tenant_id, order_key, id)', i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_documents_p' || i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_essentials_p' || i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

-- hash = blake3(symbol family): the SCIP symbol with its package version
-- replaced by 0. package_id and descriptor keep the readable parts of the
-- family (packages has scheme, manager, and name; descriptor is the SCIP
-- descriptor suffix). package_id is NULL, and descriptor holds the raw symbol,
-- for symbols that do not parse. Neither column has a foreign key or index.
-- The same family gets a separate row, and ID, in every tenant.
-- Standalone shard tables, not partitions: the writer computes the shard
-- (hash[0] >> 2, which also equals id % 64) and addresses
-- codeintel_symbols_p<shard> directly. The CHECKs keep each row in its shard.
DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_symbols_p%1$s (
            id bigint NOT NULL CONSTRAINT codeintel_symbols_p%1$s_id_check CHECK (id %% 64 = %1$s),
            tenant_id integer NOT NULL DEFAULT current_setting(''app.current_tenant'')::integer CONSTRAINT codeintel_symbols_p%1$s_tenant_id_check CHECK (tenant_id > 0),
            package_id integer,
            hash bytea NOT NULL CONSTRAINT codeintel_symbols_p%1$s_hash_check CHECK (octet_length(hash) = 32 AND get_byte(hash, 0) >> 2 = %1$s),
            descriptor text NOT NULL,
            CONSTRAINT codeintel_symbols_p%1$s_pkey PRIMARY KEY (tenant_id, hash) INCLUDE (id)
        )', i);
        EXECUTE format('CREATE INDEX IF NOT EXISTS codeintel_symbols_p%1$s_tenant_id_id ON codeintel_symbols_p%1$s(tenant_id, id)', i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_symbols_p' || i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

-- Standalone shard tables, not partitions: the writer computes the shard
-- (id % 16 or symbol_id % 64) and addresses codeintel_*_p<shard> directly.
-- The CHECK keeps each row in its shard. tenant_id follows the 8-byte ID (and
-- in occurrences pairs with the 4-byte scope_id) so that it fills alignment
-- padding. In occurrences, fixed-width columns precede the variable-length
-- order_key and ranges, in decreasing alignment, so the heap has no padding
-- before them. Payloads and packed ranges are already compact, so large values
-- are stored out of line uncompressed.
DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..15 LOOP
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_document_payloads_p%1$s (
            document_id bigint NOT NULL CHECK (document_id %% 16 = %1$s),
            tenant_id integer NOT NULL DEFAULT current_setting(''app.current_tenant'')::integer CHECK (tenant_id > 0),
            payload bytea NOT NULL,
            CONSTRAINT codeintel_document_payloads_p%1$s_document_id PRIMARY KEY (document_id, tenant_id)
        )', i);
        EXECUTE format('ALTER TABLE codeintel_document_payloads_p%s ALTER COLUMN payload SET STORAGE EXTERNAL', i);
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_essential_symbol_chunks_p%1$s (
            essential_id bigint NOT NULL CHECK (essential_id %% 16 = %1$s),
            tenant_id integer NOT NULL DEFAULT current_setting(''app.current_tenant'')::integer CHECK (tenant_id > 0),
            bucket integer NOT NULL CHECK (bucket >= 0),
            bitmap bytea NOT NULL,
            CONSTRAINT codeintel_essential_symbol_chunks_p%1$s_key PRIMARY KEY (essential_id, tenant_id, bucket)
        )', i);
        EXECUTE format('ALTER TABLE codeintel_essential_symbol_chunks_p%s ALTER COLUMN bitmap SET STORAGE EXTERNAL', i);
        -- Path chunks: the IDs of a path's documents in one scope, one bitmap
        -- per ID bucket. Standalone shard tables keyed by xxh3(order_key) % 16,
        -- which only the writer computes, so each shard has a single writer
        -- connection and needs no row locking between workers. There is
        -- deliberately no scope index: the planner preferred it to the primary
        -- key for batched key lookups.
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_document_path_chunks_p%1$s (
            tenant_id integer NOT NULL DEFAULT current_setting(''app.current_tenant'')::integer CHECK (tenant_id > 0),
            scope_id integer NOT NULL,
            bucket integer NOT NULL CHECK (bucket >= 0),
            order_key bytea NOT NULL,
            bitmap bytea NOT NULL,
            CONSTRAINT codeintel_document_path_chunks_p%1$s_key PRIMARY KEY (tenant_id, order_key, scope_id, bucket),
            CONSTRAINT codeintel_document_path_chunks_p%1$s_path FOREIGN KEY (tenant_id, order_key) REFERENCES codeintel_document_paths(tenant_id, order_key)
        )', i);
        EXECUTE format('ALTER TABLE codeintel_document_path_chunks_p%s ALTER COLUMN bitmap SET STORAGE EXTERNAL', i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_document_payloads_p' || i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_essential_symbol_chunks_p' || i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_document_path_chunks_p' || i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_definition_occurrences_p%1$s (
            symbol_id bigint NOT NULL CHECK (symbol_id %% 64 = %1$s),
            scope_id integer NOT NULL,
            tenant_id integer NOT NULL DEFAULT current_setting(''app.current_tenant'')::integer CHECK (tenant_id > 0),
            essential_id bigint NOT NULL,
            range_count integer NOT NULL CHECK (range_count > 0),
            version_token smallint NOT NULL,
            order_key bytea NOT NULL,
            ranges bytea NOT NULL,
            CONSTRAINT codeintel_definition_occurrences_p%1$s_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token)
        )', i);
        EXECUTE format('ALTER TABLE codeintel_definition_occurrences_p%s ALTER COLUMN ranges SET STORAGE EXTERNAL', i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_definition_occurrences_p' || i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_reference_occurrences_p%1$s (
            symbol_id bigint NOT NULL CHECK (symbol_id %% 64 = %1$s),
            scope_id integer NOT NULL,
            tenant_id integer NOT NULL DEFAULT current_setting(''app.current_tenant'')::integer CHECK (tenant_id > 0),
            essential_id bigint NOT NULL,
            range_count integer NOT NULL CHECK (range_count > 0),
            version_token smallint NOT NULL,
            order_key bytea NOT NULL,
            ranges bytea NOT NULL,
            CONSTRAINT codeintel_reference_occurrences_p%1$s_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token)
        )', i);
        EXECUTE format('ALTER TABLE codeintel_reference_occurrences_p%s ALTER COLUMN ranges SET STORAGE EXTERNAL', i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_reference_occurrences_p' || i);
    END LOOP;
END $$;

COMMIT AND CHAIN;

DO $$
DECLARE
    i integer;
BEGIN
    FOR i IN 0..63 LOOP
        EXECUTE format('CREATE TABLE IF NOT EXISTS codeintel_implementation_occurrences_p%1$s (
            symbol_id bigint NOT NULL CHECK (symbol_id %% 64 = %1$s),
            scope_id integer NOT NULL,
            tenant_id integer NOT NULL DEFAULT current_setting(''app.current_tenant'')::integer CHECK (tenant_id > 0),
            essential_id bigint NOT NULL,
            range_count integer NOT NULL CHECK (range_count > 0),
            version_token smallint NOT NULL,
            order_key bytea NOT NULL,
            ranges bytea NOT NULL,
            CONSTRAINT codeintel_implementation_occurrences_p%1$s_key PRIMARY KEY (symbol_id, tenant_id, scope_id, order_key, essential_id, version_token)
        )', i);
        EXECUTE format('ALTER TABLE codeintel_implementation_occurrences_p%s ALTER COLUMN ranges SET STORAGE EXTERNAL', i);
        PERFORM pg_temp.codeintel_isolate_tenant('codeintel_implementation_occurrences_p' || i);
    END LOOP;
END $$;

DROP FUNCTION IF EXISTS pg_temp.codeintel_isolate_tenant(text);
