DROP VIEW IF EXISTS insights_jobs_backfill_in_progress;

CREATE VIEW insights_jobs_backfill_in_progress WITH (security_invoker = true) AS
SELECT
    jobs.id,
    jobs.state,
    jobs.failure_message,
    jobs.queued_at,
    jobs.started_at,
    jobs.finished_at,
    jobs.process_after,
    jobs.num_resets,
    jobs.num_failures,
    jobs.last_heartbeat_at,
    jobs.execution_logs,
    jobs.worker_hostname,
    jobs.cancel,
    jobs.backfill_id,
    isb.state AS backfill_state,
    isb.estimated_cost,
    jobs.tenant_id
FROM insights_background_jobs jobs
JOIN insight_series_backfill isb ON jobs.backfill_id = isb.id
WHERE isb.state = 'processing';
