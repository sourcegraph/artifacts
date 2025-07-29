-- Remove deepsearch_quota table

DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_quota;
DROP TABLE IF EXISTS deepsearch_quota CASCADE;
