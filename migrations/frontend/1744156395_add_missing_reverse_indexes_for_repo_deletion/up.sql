CREATE INDEX IF NOT EXISTS contributor_data_repo_id ON contributor_data (repo_id);

COMMIT AND CHAIN;

CREATE INDEX IF NOT EXISTS contributor_repos_repo_id ON contributor_repos (repo_id);

COMMIT AND CHAIN;

CREATE INDEX IF NOT EXISTS contributor_jobs_repo_id ON contributor_jobs (repo_id);

COMMIT AND CHAIN;

CREATE INDEX IF NOT EXISTS repo_cleanup_jobs_repository_id ON repo_cleanup_jobs (repository_id);

COMMIT AND CHAIN;

CREATE INDEX IF NOT EXISTS zoekt_index_jobs_repository_id ON zoekt_index_jobs (repository_id);

COMMIT AND CHAIN;

CREATE INDEX IF NOT EXISTS repo_update_jobs_repository_id ON repo_update_jobs (repository_id);
