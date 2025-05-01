ALTER TABLE zoekt_repos DROP COLUMN IF EXISTS last_index_attempt_at;
ALTER TABLE zoekt_repos DROP COLUMN IF EXISTS failed_index_attempts;

DROP TABLE IF EXISTS zoekt_index_jobs;

