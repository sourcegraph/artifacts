DELETE FROM abc_workflow_instances WHERE workflow_id IS NULL;

ALTER TABLE abc_workflow_instances
ALTER COLUMN workflow_id SET NOT NULL;

ALTER TABLE abc_node_states
    DROP COLUMN IF EXISTS finished_at,
    DROP COLUMN IF EXISTS started_at;
