DO $$
DECLARE
    suffix TEXT;
    old_name TEXT;
    new_name TEXT;
    object_name TEXT;
BEGIN
    FOREACH suffix IN ARRAY ARRAY['sessions', 'session_executions', 'session_events'] LOOP
        old_name := 'execd_' || suffix;
        new_name := 'executor_' || suffix;

        EXECUTE format('ALTER TABLE IF EXISTS %I RENAME TO %I', old_name, new_name);
        EXECUTE format('ALTER SEQUENCE IF EXISTS %I RENAME TO %I', old_name || '_id_seq', new_name || '_id_seq');

        -- Renaming a constraint also renames its backing index.
        FOR object_name IN
            SELECT conname FROM pg_constraint
            WHERE conrelid = new_name::regclass
                AND starts_with(conname, old_name || '_')
        LOOP
            EXECUTE format('ALTER TABLE %I RENAME CONSTRAINT %I TO %I',
                new_name, object_name, replace(object_name, old_name, new_name));
        END LOOP;

        FOR object_name IN
            SELECT indexname FROM pg_indexes
            WHERE schemaname = current_schema() AND tablename = new_name
                AND starts_with(indexname, old_name || '_')
        LOOP
            EXECUTE format('ALTER INDEX %I RENAME TO %I',
                object_name, replace(object_name, old_name, new_name));
        END LOOP;
    END LOOP;
END $$;
