UPDATE contributor_repos SET last_processed_commit_sha = '' WHERE last_processed_commit_sha IS NULL;

ALTER TABLE contributor_repos ALTER COLUMN last_processed_commit_sha SET NOT NULL;
