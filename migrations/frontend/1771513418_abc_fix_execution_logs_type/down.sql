-- Rollback also intentionally drops all task rows because execution_logs changes
-- shape from json[] to json and we do not preserve historical task data.
DELETE FROM abc_executor_tasks;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'abc_executor_tasks'
          AND column_name = 'execution_logs'
          AND udt_name = '_json'
    ) THEN
        -- Data is intentionally discarded in this migration, so rollback coerces
        -- execution_logs to json with a NULL payload.
        ALTER TABLE abc_executor_tasks
            ALTER COLUMN execution_logs TYPE json USING NULL;
    END IF;
END
$$;
