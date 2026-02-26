-- Drop the input column and add variables column to abc_workflow_executions
ALTER TABLE abc_workflow_executions DROP COLUMN IF EXISTS input;
ALTER TABLE abc_workflow_executions ADD COLUMN IF NOT EXISTS variables JSONB NOT NULL DEFAULT '{}';

-- Drop the input column from abc_node_states (no longer used by sourceflow)
ALTER TABLE abc_node_states DROP COLUMN IF EXISTS input;
