-- Supports listing repositories by how many files Zoekt skipped at index time,
-- worst offenders first.
CREATE INDEX CONCURRENTLY IF NOT EXISTS zoekt_repos_skipped_files_total
    ON zoekt_repos (skipped_files_total DESC NULLS LAST);
