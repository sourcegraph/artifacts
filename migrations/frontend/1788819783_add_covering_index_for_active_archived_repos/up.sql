CREATE INDEX CONCURRENTLY IF NOT EXISTS repo_active_archived_id_private_idx
    ON repo (id) INCLUDE (private)
    WHERE deleted_at IS NULL
        AND blocked IS NULL
        AND NOT fork
        AND archived;
