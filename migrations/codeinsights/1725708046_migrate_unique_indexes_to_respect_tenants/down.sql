CREATE UNIQUE INDEX tmp_unique_index ON insight_view (unique_id);
DROP INDEX IF EXISTS insight_view_unique_id_unique_idx;
ALTER INDEX tmp_unique_index RENAME TO insight_view_unique_id_unique_idx;
CREATE UNIQUE INDEX IF NOT EXISTS insight_view_unique_id_unique_idx_new ON insight_view (unique_id, tenant_id);
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON metadata (metadata);
DROP INDEX IF EXISTS metadata_metadata_unique_idx;
ALTER INDEX tmp_unique_index RENAME TO metadata_metadata_unique_idx;
CREATE UNIQUE INDEX IF NOT EXISTS metadata_metadata_unique_idx_new ON metadata (metadata, tenant_id);
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON repo_names (name);
DROP INDEX IF EXISTS repo_names_name_unique_idx;
ALTER INDEX tmp_unique_index RENAME TO repo_names_name_unique_idx;
CREATE UNIQUE INDEX IF NOT EXISTS repo_names_name_unique_idx_new ON repo_names (name, tenant_id);
COMMIT AND CHAIN;
