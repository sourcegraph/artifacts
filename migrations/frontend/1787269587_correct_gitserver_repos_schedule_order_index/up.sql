CREATE INDEX CONCURRENTLY IF NOT EXISTS gitserver_repos_schedule_order_idx_corrected ON gitserver_repos (
    (last_fetch_attempt_at AT TIME ZONE 'UTC' + LEAST(GREATEST((last_fetched - last_changed) / 2, interval '45 seconds') + interval '45 seconds' * (CASE WHEN failed_fetch_attempts <= 0 THEN 0 ELSE LEAST(POWER(2, LEAST(failed_fetch_attempts, 16)), 2048) END), interval '8 hours')) DESC,
    repo_id
);
