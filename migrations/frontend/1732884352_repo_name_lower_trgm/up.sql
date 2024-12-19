CREATE INDEX CONCURRENTLY IF NOT EXISTS repo_name_lower_trgm_idx ON repo USING gin (name_lower gin_trgm_ops);
