ALTER TABLE gitserver_repos DROP COLUMN IF EXISTS last_fetch_attempt_at;

ALTER TABLE gitserver_repos DROP COLUMN IF EXISTS failed_fetch_attempts;

ALTER TABLE gitserver_repos ALTER COLUMN last_fetched SET DEFAULT NOW();
UPDATE gitserver_repos SET last_fetched = NOW() WHERE last_fetched IS NULL;
ALTER TABLE gitserver_repos ALTER COLUMN last_fetched SET NOT NULL;

ALTER TABLE gitserver_repos ALTER COLUMN last_changed SET DEFAULT NOW();
UPDATE gitserver_repos SET last_changed = NOW() WHERE last_changed IS NULL;
ALTER TABLE gitserver_repos ALTER COLUMN last_changed SET NOT NULL;

DROP TABLE IF EXISTS repo_update_jobs;
