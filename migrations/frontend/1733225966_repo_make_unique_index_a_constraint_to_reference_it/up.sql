CREATE OR REPLACE FUNCTION migrate_add_constraint_repo()
RETURNS void AS $$
BEGIN
    IF NOT EXISTS (SELECT true
        FROM information_schema.table_constraints
        WHERE constraint_name = 'repo_external_unique'
        AND table_name = 'repo'
    ) THEN
        EXECUTE format('ALTER TABLE repo ADD CONSTRAINT repo_external_unique UNIQUE USING INDEX repo_external_unique_idx');
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT migrate_add_constraint_repo();

DROP FUNCTION migrate_add_constraint_repo();
