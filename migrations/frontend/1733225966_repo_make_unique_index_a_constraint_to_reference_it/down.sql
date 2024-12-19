CREATE UNIQUE INDEX IF NOT EXISTS repo_external_unique_idx ON repo (external_service_type, external_service_id, external_id, tenant_id);
ALTER TABLE repo DROP CONSTRAINT IF EXISTS repo_external_unique;
