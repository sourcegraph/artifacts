ALTER TABLE abc_iteration_items ADD COLUMN IF NOT EXISTS parent_instance_id BIGINT REFERENCES abc_workflow_instances(id);

-- Backfill from iterator_id format "instanceID:nodeSpecID"
UPDATE abc_iteration_items
SET parent_instance_id = CAST(split_part(iterator_id, ':', 1) AS BIGINT)
WHERE parent_instance_id IS NULL;

CREATE INDEX IF NOT EXISTS abc_iteration_items_parent_instance_id_idx ON abc_iteration_items(tenant_id, parent_instance_id);

ALTER TABLE abc_workflow_instances DROP CONSTRAINT IF EXISTS abc_workflow_instances_lifecycle_phase_check;
ALTER TABLE abc_workflow_instances ADD CONSTRAINT abc_workflow_instances_lifecycle_phase_check CHECK (lifecycle_phase IN ('queued', 'running', 'paused', 'complete', 'failed'));

-- Update partial index to also exclude paused instances from the claimable set
DROP INDEX IF EXISTS abc_workflow_instances_lifecycle_phase_idx;
CREATE INDEX abc_workflow_instances_lifecycle_phase_idx ON abc_workflow_instances (tenant_id, lifecycle_phase) WHERE lifecycle_phase IN ('queued', 'running');
