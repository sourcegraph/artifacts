ALTER TABLE exhaustive_search_jobs ADD COLUMN IF NOT EXISTS description text;

ALTER TABLE exhaustive_search_jobs DROP CONSTRAINT IF EXISTS exhaustive_search_jobs_description_length_check;
ALTER TABLE exhaustive_search_jobs ADD CONSTRAINT exhaustive_search_jobs_description_length_check CHECK (length(description) <= 200);