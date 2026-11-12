-- Supports paging through repositories with skipped files, ordered by how many
-- files Zoekt skipped. repo_id breaks ties, so a keyset cursor can seek
-- straight to its position even when many repositories share a count.
CREATE INDEX CONCURRENTLY IF NOT EXISTS zoekt_repos_skipped_files_total_repo_id
    ON zoekt_repos (skipped_files_total, repo_id)
    WHERE skipped_files_total > 0;
