-- Code no longer writes or reads pending_repo_permissions.permission, which was
-- always 'read', so new rows take the value from this default until the column
-- is dropped.
ALTER TABLE pending_repo_permissions ALTER COLUMN permission SET DEFAULT 'read';

-- Rows with any other permission were never read, and they would break the
-- unique index on the remaining columns added in the next migration.
DELETE FROM pending_repo_permissions WHERE permission <> 'read';
