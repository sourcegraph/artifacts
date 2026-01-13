ALTER TABLE slack_configurations DROP CONSTRAINT IF EXISTS slack_configurations_unique_tenant;
ALTER TABLE slack_configurations ADD CONSTRAINT slack_configurations_unique_tenant UNIQUE (tenant_id);
