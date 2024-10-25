-- Purpose of this migration is to include tenant_id in the unique indexes for
-- batch_changes. We are using a more conservative approach for other tables,
-- but can't do that since it is a partial index. Given this table is smaller
-- than most, we do a full migration to tenant_id.

-- unwritten columns become default tenant_id.
UPDATE batch_changes SET tenant_id = 1 WHERE tenant_id IS NULL;

-- we still can't rely on session variable, so we set default to default tenant.
ALTER TABLE batch_changes
  ALTER COLUMN tenant_id SET DEFAULT COALESCE(current_setting('app.current_tenant', true), '1')::integer,
  ALTER COLUMN tenant_id SET NOT NULL;

-- we need to include tenant_id in the two unique indexes.
CREATE UNIQUE INDEX tmp_unique_index ON batch_changes (name, namespace_org_id, tenant_id) WHERE namespace_org_id IS NOT NULL;
DROP INDEX IF EXISTS batch_changes_unique_org_id;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_unique_org_id;

CREATE UNIQUE INDEX tmp_unique_index ON batch_changes (name, namespace_user_id, tenant_id) WHERE namespace_user_id IS NOT NULL;
DROP INDEX IF EXISTS batch_changes_unique_user_id;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_unique_user_id;
