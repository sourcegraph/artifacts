ALTER TABLE batch_changes
  ALTER COLUMN tenant_id SET DEFAULT NULL,
  ALTER COLUMN tenant_id DROP NOT NULL;

CREATE UNIQUE INDEX tmp_unique_index ON batch_changes (name, namespace_org_id) WHERE namespace_org_id IS NOT NULL;
DROP INDEX IF EXISTS batch_changes_unique_org_id;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_unique_org_id;

CREATE UNIQUE INDEX tmp_unique_index ON batch_changes (name, namespace_user_id) WHERE namespace_user_id IS NOT NULL;
DROP INDEX IF EXISTS batch_changes_unique_user_id;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_unique_user_id;
