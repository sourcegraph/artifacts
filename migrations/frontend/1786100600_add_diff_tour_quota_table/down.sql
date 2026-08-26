-- Remove diff_tour_quota table

DROP POLICY IF EXISTS tenant_isolation_policy ON diff_tour_quota;
DROP TABLE IF EXISTS diff_tour_quota CASCADE;
