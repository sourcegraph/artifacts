DROP TABLE IF EXISTS codeintel_ranking_graph_keys;
DROP TABLE IF EXISTS codeintel_ranking_path_counts_inputs;
DROP TABLE IF EXISTS codeintel_ranking_progress;
DROP TABLE IF EXISTS codeintel_ranking_definitions;
DROP TABLE IF EXISTS codeintel_ranking_references_processed;
DROP TABLE IF EXISTS codeintel_ranking_references;
DROP TABLE IF EXISTS codeintel_initial_path_ranks_processed;
DROP TABLE IF EXISTS codeintel_initial_path_ranks;
DROP TABLE IF EXISTS codeintel_ranking_exports;
DROP TABLE IF EXISTS codeintel_path_ranks;

DROP FUNCTION IF EXISTS update_codeintel_path_ranks_updated_at_column();
DROP FUNCTION IF EXISTS update_codeintel_path_ranks_statistics_columns();
