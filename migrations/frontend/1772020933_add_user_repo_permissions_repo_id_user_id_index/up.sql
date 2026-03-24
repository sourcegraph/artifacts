CREATE INDEX CONCURRENTLY IF NOT EXISTS user_repo_permissions_repo_id_user_id_idx
    ON user_repo_permissions (repo_id, user_id);
