-- There is no way to preserve the underlying index, so we recreate it.

ALTER TABLE repo DROP CONSTRAINT IF EXISTS repo_name_lower_unique;

CREATE UNIQUE INDEX IF NOT EXISTS repo_name_lower_unique_tmp ON repo (name_lower, tenant_id);
