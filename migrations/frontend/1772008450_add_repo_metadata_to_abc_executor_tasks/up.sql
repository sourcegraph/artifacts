-- Existing repo metadata additions for executor tasks.
ALTER TABLE abc_executor_tasks ADD COLUMN IF NOT EXISTS repo_name TEXT;
ALTER TABLE abc_executor_tasks ADD COLUMN IF NOT EXISTS commit TEXT;

-- Add ownership columns used for repo authz + executor secret resolution.
-- We add them as nullable first, backfill/cleanup, then enforce NOT NULL.
ALTER TABLE abc_workflow_instances ADD COLUMN IF NOT EXISTS user_id INTEGER;
ALTER TABLE abc_executor_tasks ADD COLUMN IF NOT EXISTS user_id INTEGER;

-- Remove legacy/broken rows we cannot recover before enforcing NOT NULL.
DELETE FROM abc_iteration_items;
DELETE FROM abc_executor_tasks;
DELETE FROM abc_workflow_instances;

-- Keep FK definitions deterministic while remaining idempotent.
-- Postgres does not support ADD CONSTRAINT IF NOT EXISTS.
ALTER TABLE abc_workflow_instances DROP CONSTRAINT IF EXISTS abc_workflow_instances_user_id_fkey;
ALTER TABLE abc_workflow_instances
    ADD CONSTRAINT abc_workflow_instances_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE abc_executor_tasks DROP CONSTRAINT IF EXISTS abc_executor_tasks_user_id_fkey;
ALTER TABLE abc_executor_tasks
    ADD CONSTRAINT abc_executor_tasks_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Support common owner-scoped lookups while preserving tenant isolation.
CREATE INDEX IF NOT EXISTS abc_workflow_instances_tenant_user_id_idx ON abc_workflow_instances (tenant_id, user_id);
CREATE INDEX IF NOT EXISTS abc_executor_tasks_tenant_user_id_idx ON abc_executor_tasks (tenant_id, user_id);

-- Enforce strict ownership invariants in the database.
ALTER TABLE abc_workflow_instances ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE abc_executor_tasks ALTER COLUMN user_id SET NOT NULL;

-- Enforce non-null repo metadata now that all tasks supply these fields.
ALTER TABLE abc_executor_tasks ALTER COLUMN repo_name SET NOT NULL;
ALTER TABLE abc_executor_tasks ALTER COLUMN commit SET NOT NULL;
