DO $$
BEGIN
    IF to_regclass('gitserver_repos_schedule_order_idx_corrected') IS NULL
        AND to_regclass('gitserver_repos_schedule_order_idx') IS NOT NULL THEN
        ALTER INDEX gitserver_repos_schedule_order_idx RENAME TO gitserver_repos_schedule_order_idx_corrected;
    END IF;
END
$$;

CREATE INDEX IF NOT EXISTS gitserver_repos_schedule_order_idx ON gitserver_repos (
    (timezone('UTC'::text, last_fetch_attempt_at) + LEAST(GREATEST((last_fetched - last_changed) / 2::double precision * (failed_fetch_attempts + 1)::double precision, '00:00:45'::interval), '08:00:00'::interval)) DESC,
    repo_id
);
