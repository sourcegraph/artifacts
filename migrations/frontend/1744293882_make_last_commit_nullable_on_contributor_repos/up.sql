ALTER TABLE contributor_repos ALTER COLUMN last_processed_commit_sha DROP NOT NULL;

UPDATE contributor_repos SET last_processed_commit_sha = NULL WHERE last_processed_commit_sha = '';
