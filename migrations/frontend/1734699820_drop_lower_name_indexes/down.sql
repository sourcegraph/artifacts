CREATE INDEX IF NOT EXISTS repo_name_idx ON repo USING btree (lower((name)::text) COLLATE "C");
CREATE INDEX IF NOT EXISTS repo_name_trgm ON repo USING gin (lower((name)::text) gin_trgm_ops);
