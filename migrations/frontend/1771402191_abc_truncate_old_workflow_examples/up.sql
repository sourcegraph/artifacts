-- Truncate abc workflow tables to prepare for the Definition -> NodeSpecs migration.
-- Old rows stored the full definition JSON; new code expects only the nodes array.
DELETE FROM abc_container_executions;
DELETE FROM abc_node_states;
DELETE FROM abc_workflow_instances;
DELETE FROM abc_workflows;
