CREATE INDEX CONCURRENTLY IF NOT EXISTS repo_update_jobs_dequeue_optimization_idx ON repo_update_jobs
    -- This matches the ordering defined in the dbworker config.
    (priority DESC, COALESCE(process_after, queued_at) ASC, id ASC)
    -- Include state and process_after so we can use this index filtering on state and
    -- process_after. We generate a query condition similar to the one below in dbworker:
    -- ( ( state = 'queued'
    --     AND (process_after IS NULL
    --       OR process_after <= now()) )
    --   OR ( 2 > 0
    --     AND state = 'errored'
    --     AND now() - finished_at > (60 * '1 second'::INTERVAL) ) )
    INCLUDE (state, process_after)
-- Limit the index to queued and errored jobs, so that we never have to visit completed or
-- processing jobs in the post-filtering to satisfy the process_after and state condition above.
WHERE state IN ('queued', 'errored');
