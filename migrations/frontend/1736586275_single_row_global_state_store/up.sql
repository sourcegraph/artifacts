-- Keep only one entry per tenant, preferably the one that is marked as initialized.
WITH candidates AS (
    SELECT
        site_id, tenant_id, ROW_NUMBER() OVER (PARTITION BY tenant_id ORDER BY initialized DESC) AS row_num
    FROM
        global_state
), duplicates AS (
	SELECT
		site_id, tenant_id
	FROM
		candidates
	WHERE row_num > 1
)
DELETE FROM global_state
USING duplicates
WHERE global_state.site_id = duplicates.site_id AND global_state.tenant_id = duplicates.tenant_id;

ALTER TABLE global_state DROP CONSTRAINT IF EXISTS global_state_one_per_tenant;
ALTER TABLE global_state ADD CONSTRAINT global_state_one_per_tenant UNIQUE (tenant_id);
