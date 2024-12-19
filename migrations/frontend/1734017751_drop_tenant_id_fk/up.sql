DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'repo_update_jobs_tenant_id_fkey'
        AND table_name = 'repo_update_jobs'
    ) THEN
        ALTER TABLE repo_update_jobs DROP CONSTRAINT repo_update_jobs_tenant_id_fkey;
    END IF;
END $$;
