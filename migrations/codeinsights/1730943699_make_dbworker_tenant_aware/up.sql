CREATE POLICY isolation_policy_2 ON insights_data_retention_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON insights_data_retention_jobs;
ALTER POLICY isolation_policy_2 ON insights_data_retention_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON insights_background_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON insights_background_jobs;
ALTER POLICY isolation_policy_2 ON insights_background_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW insights_jobs_backfill_in_progress AS
 SELECT jobs.id,
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
    width_bucket(isb.estimated_cost, (0)::double precision, max((isb.estimated_cost + (1)::double precision)) OVER (), 4) AS cost_bucket,
    jobs.tenant_id
   FROM (insights_background_jobs jobs
     JOIN insight_series_backfill isb ON ((jobs.backfill_id = isb.id)))
  WHERE (isb.state = 'processing'::text);
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW insights_jobs_backfill_new AS
 SELECT jobs.id,
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
   FROM (insights_background_jobs jobs
     JOIN insight_series_backfill isb ON ((jobs.backfill_id = isb.id)))
  WHERE (isb.state = 'new'::text);
