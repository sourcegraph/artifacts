ALTER TABLE exhaustive_search_jobs DROP CONSTRAINT IF EXISTS exhaustive_search_jobs_request_id_key;

ALTER TABLE exhaustive_search_jobs DROP COLUMN IF EXISTS request_id;
