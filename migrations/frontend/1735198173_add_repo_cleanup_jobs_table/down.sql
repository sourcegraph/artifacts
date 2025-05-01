ALTER TABLE gitserver_repos DROP COLUMN IF EXISTS last_cleanup_attempt_at;
ALTER TABLE gitserver_repos DROP COLUMN IF EXISTS failed_cleanup_attempts;
ALTER TABLE gitserver_repos DROP COLUMN IF EXISTS last_cleaned_at;

DROP TABLE IF EXISTS repo_cleanup_jobs;
