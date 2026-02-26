-- Restore input column to abc_workflow_executions
ALTER TABLE abc_workflow_executions DROP COLUMN IF EXISTS variables;
ALTER TABLE abc_workflow_executions ADD COLUMN IF NOT EXISTS input TEXT NOT NULL DEFAULT '';

-- Restore input column to abc_node_states
ALTER TABLE abc_node_states ADD COLUMN IF NOT EXISTS input TEXT NOT NULL DEFAULT '';
