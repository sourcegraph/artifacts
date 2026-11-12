CREATE INDEX IF NOT EXISTS user_repo_permissions_updated_at_idx
    ON user_repo_permissions USING btree (updated_at);
