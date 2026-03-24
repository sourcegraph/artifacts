-- Revert repo metadata columns.
ALTER TABLE abc_executor_tasks DROP COLUMN IF EXISTS commit;
ALTER TABLE abc_executor_tasks DROP COLUMN IF EXISTS repo_name;

-- Remove ownership foreign keys before dropping columns.
ALTER TABLE abc_executor_tasks DROP CONSTRAINT IF EXISTS abc_executor_tasks_user_id_fkey;
ALTER TABLE abc_workflow_instances DROP CONSTRAINT IF EXISTS abc_workflow_instances_user_id_fkey;

-- Remove owner lookup indexes.
DROP INDEX IF EXISTS abc_executor_tasks_tenant_user_id_idx;
DROP INDEX IF EXISTS abc_workflow_instances_tenant_user_id_idx;

-- Drop ownership columns.
ALTER TABLE abc_executor_tasks DROP COLUMN IF EXISTS user_id;
ALTER TABLE abc_workflow_instances DROP COLUMN IF EXISTS user_id;
