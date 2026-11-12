CREATE INDEX IF NOT EXISTS zoekt_repos_skipped_files_total
    ON zoekt_repos (skipped_files_total DESC NULLS LAST);
