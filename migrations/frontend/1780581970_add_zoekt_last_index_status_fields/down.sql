ALTER TABLE zoekt_repos ADD COLUMN IF NOT EXISTS last_index_attempt_at timestamp with time zone;
ALTER TABLE zoekt_repos ADD COLUMN IF NOT EXISTS failed_index_attempts integer NOT NULL DEFAULT 0;

ALTER TABLE zoekt_repos DROP COLUMN IF EXISTS last_index_failure_message;
ALTER TABLE zoekt_repos DROP COLUMN IF EXISTS last_index_status;
