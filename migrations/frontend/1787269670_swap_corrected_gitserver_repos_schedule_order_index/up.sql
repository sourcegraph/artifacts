-- Keep the corrected index available while atomically replacing the old definition.
DO $$
BEGIN
    IF to_regclass('gitserver_repos_schedule_order_idx_corrected') IS NOT NULL THEN
        DROP INDEX IF EXISTS gitserver_repos_schedule_order_idx;
        ALTER INDEX gitserver_repos_schedule_order_idx_corrected RENAME TO gitserver_repos_schedule_order_idx;
    END IF;
END
$$;
