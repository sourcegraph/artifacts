-- No query filters or sorts user_repo_permissions by updated_at through this
-- index. Keeping it indexed makes every update of updated_at a non-HOT update
-- that also writes to every other index of the table.
DROP INDEX IF EXISTS user_repo_permissions_updated_at_idx;
