ALTER TABLE abc_workflow_instances DROP COLUMN IF EXISTS name;
ALTER TABLE abc_workflow_instances DROP COLUMN IF EXISTS input_schema;

ALTER TABLE abc_workflow_instances
    DROP CONSTRAINT IF EXISTS abc_workflow_instances_workflow_id_fkey;
ALTER TABLE abc_workflow_instances
    ADD CONSTRAINT abc_workflow_instances_workflow_id_fkey
    FOREIGN KEY (workflow_id) REFERENCES abc_workflows(id) ON DELETE CASCADE;
