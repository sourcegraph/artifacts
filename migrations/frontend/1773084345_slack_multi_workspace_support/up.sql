-- Add team_id column to identify which Slack workspace each configuration belongs to.
ALTER TABLE slack_configurations ADD COLUMN IF NOT EXISTS team_id TEXT NOT NULL DEFAULT '';

-- Drop the old single-workspace-per-tenant constraint.
ALTER TABLE slack_configurations DROP CONSTRAINT IF EXISTS slack_configurations_unique_tenant;

-- Add a new unique constraint allowing multiple workspaces per tenant, but only one config per workspace.
CREATE UNIQUE INDEX IF NOT EXISTS slack_configurations_unique_tenant_team
    ON slack_configurations (tenant_id, team_id);

-- Add slack_configuration_id to conversation mappings to scope them to a specific workspace.
ALTER TABLE slack_conversation_mappings ADD COLUMN IF NOT EXISTS slack_configuration_id INTEGER REFERENCES slack_configurations(id) ON DELETE CASCADE;
