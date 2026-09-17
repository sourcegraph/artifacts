CREATE INDEX CONCURRENTLY IF NOT EXISTS repo_active_id_idx
    ON repo (id)
    WHERE deleted_at IS NULL AND blocked IS NULL;
