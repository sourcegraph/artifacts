DROP INDEX IF EXISTS abc_iteration_items_parent_instance_id_idx;
ALTER TABLE abc_iteration_items DROP COLUMN IF EXISTS parent_instance_id;

-- Remove 'paused' from the allowed lifecycle phases.
-- Any instances currently in 'paused' state must be moved back to 'running' first.
UPDATE abc_workflow_instances SET lifecycle_phase = 'running' WHERE lifecycle_phase = 'paused';

ALTER TABLE abc_workflow_instances DROP CONSTRAINT IF EXISTS abc_workflow_instances_lifecycle_phase_check;
ALTER TABLE abc_workflow_instances ADD CONSTRAINT abc_workflow_instances_lifecycle_phase_check CHECK (lifecycle_phase IN ('queued', 'running', 'complete', 'failed'));
