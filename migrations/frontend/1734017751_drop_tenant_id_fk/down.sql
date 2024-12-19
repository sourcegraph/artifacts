DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'repo_update_jobs_tenant_id_fkey'
        AND table_name = 'repo_update_jobs'
    ) THEN
        ALTER TABLE repo_update_jobs
        ADD CONSTRAINT repo_update_jobs_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES tenants(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE;
    END IF;
END $$;
