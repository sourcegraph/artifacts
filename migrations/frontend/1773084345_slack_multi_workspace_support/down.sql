-- Remove slack_configuration_id from conversation mappings.
ALTER TABLE slack_conversation_mappings DROP COLUMN IF EXISTS slack_configuration_id;

-- Drop the multi-workspace unique constraint.
DROP INDEX IF EXISTS slack_configurations_unique_tenant_team;

-- Restore the single-workspace-per-tenant constraint.
ALTER TABLE slack_configurations DROP CONSTRAINT IF EXISTS slack_configurations_unique_tenant;
ALTER TABLE slack_configurations ADD CONSTRAINT slack_configurations_unique_tenant UNIQUE (tenant_id);

-- Remove team_id column.
ALTER TABLE slack_configurations DROP COLUMN IF EXISTS team_id;
