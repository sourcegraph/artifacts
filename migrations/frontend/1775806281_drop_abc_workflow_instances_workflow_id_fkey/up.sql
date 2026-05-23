ALTER TABLE abc_workflow_instances DROP CONSTRAINT IF EXISTS abc_workflow_instances_workflow_id_fkey;
ALTER TABLE abc_workflow_instances ADD COLUMN IF NOT EXISTS name TEXT NOT NULL DEFAULT '';
ALTER TABLE abc_workflow_instances ADD COLUMN IF NOT EXISTS input_schema TEXT;
