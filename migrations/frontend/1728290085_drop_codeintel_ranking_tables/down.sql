-- codeintel_ranking_exports

CREATE TABLE IF NOT EXISTS codeintel_ranking_exports (
                                           upload_id integer REFERENCES lsif_uploads(id) ON DELETE SET NULL,
                                           graph_key text NOT NULL,
                                           locked_at timestamp with time zone NOT NULL DEFAULT now(),
                                           id SERIAL PRIMARY KEY,
                                           last_scanned_at timestamp with time zone,
                                           deleted_at timestamp with time zone,
                                           upload_key text,
                                           tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS codeintel_ranking_exports_graph_key_deleted_at_id ON codeintel_ranking_exports(graph_key text_ops,deleted_at timestamptz_ops DESC,id int4_ops);
CREATE INDEX IF NOT EXISTS codeintel_ranking_exports_graph_key_last_scanned_at ON codeintel_ranking_exports(graph_key text_ops,last_scanned_at timestamptz_ops NULLS FIRST,id int4_ops);

ALTER TABLE codeintel_ranking_exports ALTER COLUMN tenant_id SET DEFAULT 1;
ALTER TABLE codeintel_ranking_exports DROP CONSTRAINT IF EXISTS codeintel_ranking_exports_graph_key_upload_id;
ALTER TABLE codeintel_ranking_exports ADD CONSTRAINT codeintel_ranking_exports_graph_key_upload_id UNIQUE (graph_key, upload_id);

-- codeintel_ranking_definitions

CREATE TABLE IF NOT EXISTS codeintel_ranking_definitions (
                                               id BIGSERIAL PRIMARY KEY,
                                               symbol_name text NOT NULL,
                                               document_path text NOT NULL,
                                               graph_key text NOT NULL,
                                               exported_upload_id integer NOT NULL REFERENCES codeintel_ranking_exports(id) ON DELETE CASCADE,
                                               symbol_checksum bytea NOT NULL DEFAULT '\x'::bytea,
                                               tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE INDEX IF NOT EXISTS codeintel_ranking_definitions_exported_upload_id ON codeintel_ranking_definitions(exported_upload_id int4_ops);
CREATE INDEX IF NOT EXISTS codeintel_ranking_definitions_graph_key_symbol_checksum_search ON codeintel_ranking_definitions(graph_key text_ops,symbol_checksum bytea_ops,exported_upload_id int4_ops,document_path text_ops);

ALTER TABLE codeintel_ranking_definitions ALTER COLUMN tenant_id SET DEFAULT 1;

-- codeintel_ranking_graph_keys

CREATE TABLE IF NOT EXISTS codeintel_ranking_graph_keys (
                                              id SERIAL PRIMARY KEY,
                                              graph_key text NOT NULL,
                                              created_at timestamp with time zone DEFAULT now(),
                                              tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);

ALTER TABLE codeintel_ranking_graph_keys ALTER COLUMN tenant_id SET DEFAULT 1;

-- codeintel_ranking_path_counts_inputs

CREATE TABLE IF NOT EXISTS codeintel_ranking_path_counts_inputs (
                                                      id BIGSERIAL PRIMARY KEY,
                                                      count integer NOT NULL,
                                                      graph_key text NOT NULL,
                                                      processed boolean NOT NULL DEFAULT false,
                                                      definition_id bigint,
                                                      tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS codeintel_ranking_path_counts_inputs_graph_key_id ON codeintel_ranking_path_counts_inputs(graph_key text_ops,id int8_ops);
CREATE UNIQUE INDEX IF NOT EXISTS codeintel_ranking_path_counts_inputs_graph_key_unique_definitio ON codeintel_ranking_path_counts_inputs(graph_key text_ops,definition_id int8_ops) WHERE NOT processed;

ALTER TABLE codeintel_ranking_path_counts_inputs ALTER COLUMN tenant_id SET DEFAULT 1;

-- codeintel_ranking_progress

CREATE TABLE IF NOT EXISTS codeintel_ranking_progress (
                                            id BIGSERIAL PRIMARY KEY,
                                            graph_key text NOT NULL UNIQUE,
                                            mappers_started_at timestamp with time zone NOT NULL,
                                            mapper_completed_at timestamp with time zone,
                                            seed_mapper_completed_at timestamp with time zone,
                                            reducer_started_at timestamp with time zone,
                                            reducer_completed_at timestamp with time zone,
                                            num_path_records_total integer,
                                            num_reference_records_total integer,
                                            num_count_records_total integer,
                                            num_path_records_processed integer,
                                            num_reference_records_processed integer,
                                            num_count_records_processed integer,
                                            max_export_id bigint NOT NULL,
                                            reference_cursor_export_deleted_at timestamp with time zone,
                                            reference_cursor_export_id integer,
                                            path_cursor_deleted_export_at timestamp with time zone,
                                            path_cursor_export_id integer,
                                            tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);

ALTER TABLE codeintel_ranking_progress ALTER COLUMN tenant_id SET DEFAULT 1;

-- codeintel_ranking_references

CREATE TABLE IF NOT EXISTS codeintel_ranking_references (
                                              id BIGSERIAL PRIMARY KEY,
                                              symbol_names text[] NOT NULL,
                                              graph_key text NOT NULL,
                                              exported_upload_id integer NOT NULL REFERENCES codeintel_ranking_exports(id) ON DELETE CASCADE,
                                              symbol_checksums bytea[] NOT NULL DEFAULT '{}'::bytea[],
                                              tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);
COMMENT ON TABLE codeintel_ranking_references IS 'References for a given upload proceduced by background job consuming SCIP indexes.';

CREATE INDEX IF NOT EXISTS codeintel_ranking_references_exported_upload_id ON codeintel_ranking_references(exported_upload_id int4_ops);
CREATE INDEX IF NOT EXISTS codeintel_ranking_references_graph_key_id ON codeintel_ranking_references(graph_key text_ops,id int8_ops);

ALTER TABLE codeintel_ranking_references ALTER COLUMN tenant_id SET DEFAULT 1;

-- codeintel_ranking_references_processed

CREATE TABLE IF NOT EXISTS codeintel_ranking_references_processed (
                                                        graph_key text NOT NULL,
                                                        codeintel_ranking_reference_id integer NOT NULL,
                                                        id BIGSERIAL PRIMARY KEY,
                                                        tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS codeintel_ranking_references_processed_graph_key_codeintel_rank ON codeintel_ranking_references_processed(graph_key text_ops,codeintel_ranking_reference_id int4_ops);
CREATE INDEX IF NOT EXISTS codeintel_ranking_references_processed_reference_id ON codeintel_ranking_references_processed(codeintel_ranking_reference_id int4_ops);

ALTER TABLE codeintel_ranking_references_processed ALTER COLUMN tenant_id SET DEFAULT 1;
ALTER TABLE codeintel_ranking_references_processed DROP CONSTRAINT IF EXISTS fk_codeintel_ranking_reference;
ALTER TABLE codeintel_ranking_references_processed ADD CONSTRAINT fk_codeintel_ranking_reference FOREIGN KEY (codeintel_ranking_reference_id) REFERENCES codeintel_ranking_references(id) ON DELETE CASCADE;

-- codeintel_initial_path_ranks

CREATE TABLE IF NOT EXISTS codeintel_initial_path_ranks (
                                              id BIGSERIAL PRIMARY KEY,
                                              document_path text NOT NULL DEFAULT ''::text,
                                              graph_key text NOT NULL,
                                              document_paths text[] NOT NULL DEFAULT '{}'::text[],
                                              exported_upload_id integer NOT NULL REFERENCES codeintel_ranking_exports(id) ON DELETE CASCADE,
                                              tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS codeintel_initial_path_ranks_exported_upload_id ON codeintel_initial_path_ranks(exported_upload_id int4_ops);
CREATE INDEX IF NOT EXISTS codeintel_initial_path_ranks_graph_key_id ON codeintel_initial_path_ranks(graph_key text_ops,id int8_ops);

ALTER TABLE codeintel_initial_path_ranks ALTER COLUMN tenant_id SET DEFAULT 1;

-- codeintel-initial-path-ranks-processed

CREATE TABLE IF NOT EXISTS codeintel_initial_path_ranks_processed (
                                                        id BIGSERIAL PRIMARY KEY,
                                                        graph_key text NOT NULL,
                                                        codeintel_initial_path_ranks_id bigint NOT NULL,
                                                        tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS codeintel_initial_path_ranks_processed_cgraph_key_codeintel_ini ON codeintel_initial_path_ranks_processed(graph_key text_ops,codeintel_initial_path_ranks_id int8_ops);
CREATE INDEX IF NOT EXISTS codeintel_initial_path_ranks_processed_codeintel_initial_path_r ON codeintel_initial_path_ranks_processed(codeintel_initial_path_ranks_id int8_ops);

ALTER TABLE codeintel_initial_path_ranks_processed ALTER COLUMN tenant_id SET DEFAULT 1;

ALTER TABLE codeintel_initial_path_ranks_processed DROP CONSTRAINT IF EXISTS fk_codeintel_initial_path_ranks;
ALTER TABLE codeintel_initial_path_ranks_processed ADD CONSTRAINT fk_codeintel_initial_path_ranks FOREIGN KEY (codeintel_initial_path_ranks_id) REFERENCES codeintel_initial_path_ranks(id) ON DELETE CASCADE;

-- codeintel_path_ranks

CREATE TABLE IF NOT EXISTS codeintel_path_ranks
(
    repository_id   integer                  NOT NULL,
    payload         jsonb                    NOT NULL,
    updated_at      timestamp with time zone NOT NULL DEFAULT now(),
    graph_key       text                     NOT NULL,
    num_paths       integer,
    refcount_logsum double precision,
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       integer REFERENCES tenants (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT codeintel_path_ranks_graph_key_repository_id UNIQUE (graph_key, repository_id)
);

CREATE INDEX IF NOT EXISTS codeintel_path_ranks_graph_key ON codeintel_path_ranks (graph_key text_ops, updated_at timestamptz_ops NULLS FIRST, id int8_ops);
CREATE INDEX IF NOT EXISTS codeintel_path_ranks_repository_id_updated_at_id ON codeintel_path_ranks (repository_id int4_ops,
                                                                                       updated_at timestamptz_ops NULLS
                                                                                       FIRST, id int8_ops);

ALTER TABLE codeintel_path_ranks ALTER COLUMN tenant_id SET DEFAULT 1;

CREATE OR REPLACE FUNCTION update_codeintel_path_ranks_statistics_columns() RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    SELECT COUNT(r.v)                AS num_paths,
           SUM(LOG(2, r.v::int + 1)) AS refcount_logsum
    INTO
        NEW.num_paths,
        NEW.refcount_logsum
    FROM jsonb_each(
             CASE
                 WHEN NEW.payload::text = 'null'
                     THEN '{}'::jsonb
                 ELSE COALESCE(NEW.payload, '{}'::jsonb)
                 END
         ) r(k, v);

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION update_codeintel_path_ranks_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS insert_codeintel_path_ranks_statistics on codeintel_path_ranks;
DROP TRIGGER IF EXISTS update_codeintel_path_ranks_statistics on codeintel_path_ranks;
DROP TRIGGER IF EXISTS update_codeintel_path_ranks_updated_at on codeintel_path_ranks;

CREATE TRIGGER insert_codeintel_path_ranks_statistics
    BEFORE INSERT
    ON codeintel_path_ranks
    FOR EACH ROW
EXECUTE FUNCTION update_codeintel_path_ranks_statistics_columns();

CREATE TRIGGER update_codeintel_path_ranks_statistics
    BEFORE UPDATE
    ON codeintel_path_ranks
    FOR EACH ROW
    WHEN ((new.* IS DISTINCT FROM old.*))
EXECUTE FUNCTION update_codeintel_path_ranks_statistics_columns();

CREATE TRIGGER update_codeintel_path_ranks_updated_at
    BEFORE UPDATE
    ON codeintel_path_ranks
    FOR EACH ROW
    WHEN ((new.* IS DISTINCT FROM old.*))
EXECUTE FUNCTION update_codeintel_path_ranks_updated_at_column();
