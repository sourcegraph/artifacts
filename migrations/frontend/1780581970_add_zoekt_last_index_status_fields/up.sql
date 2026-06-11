ALTER TABLE zoekt_repos ADD COLUMN IF NOT EXISTS last_index_status text;
ALTER TABLE zoekt_repos ADD COLUMN IF NOT EXISTS last_index_failure_message text;

ALTER TABLE zoekt_repos DROP COLUMN IF EXISTS last_index_attempt_at;
ALTER TABLE zoekt_repos DROP COLUMN IF EXISTS failed_index_attempts;
