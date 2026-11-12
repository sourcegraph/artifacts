CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS user_repo_permissions_unrestricted_unique_idx
    ON user_repo_permissions USING btree (repo_id) WHERE user_id IS NULL;
