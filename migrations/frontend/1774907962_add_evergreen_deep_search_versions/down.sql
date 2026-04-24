DROP TABLE IF EXISTS evergreen_deep_search_versions CASCADE;

ALTER TABLE evergreen_deep_search DROP COLUMN IF EXISTS updated_at;
