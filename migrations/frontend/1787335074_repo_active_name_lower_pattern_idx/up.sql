CREATE INDEX CONCURRENTLY IF NOT EXISTS repo_active_name_lower_pattern_idx
    ON repo (name_lower text_pattern_ops)
    WHERE deleted_at IS NULL
        AND blocked IS NULL
        AND NOT fork
        AND NOT archived;
