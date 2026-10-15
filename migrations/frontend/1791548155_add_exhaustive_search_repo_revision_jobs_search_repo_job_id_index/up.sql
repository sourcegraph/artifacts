-- Without this index, the ON DELETE CASCADE from exhaustive_search_repo_jobs
-- does a sequential scan of exhaustive_search_repo_revision_jobs for every
-- deleted repo job, which makes deleting a large search job quadratic.
CREATE INDEX CONCURRENTLY IF NOT EXISTS exhaustive_search_repo_revision_jobs_search_repo_job_id
    ON exhaustive_search_repo_revision_jobs (search_repo_job_id);
