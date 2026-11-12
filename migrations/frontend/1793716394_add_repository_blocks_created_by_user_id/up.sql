-- NULL for rules created before this column existed, by an internal actor, or
-- by a user who has since been hard-deleted.
ALTER TABLE repository_blocks ADD COLUMN IF NOT EXISTS created_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL;
