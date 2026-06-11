ALTER TABLE batch_spec_workspace_execution_jobs
    ADD COLUMN IF NOT EXISTS changeset_hook_job_id bigint;

CREATE UNIQUE INDEX IF NOT EXISTS batch_spec_workspace_execution_jobs_changeset_hook_job_id
    ON batch_spec_workspace_execution_jobs (tenant_id, changeset_hook_job_id)
    WHERE changeset_hook_job_id IS NOT NULL;

CREATE OR REPLACE VIEW batch_spec_workspace_execution_jobs_with_rank WITH (security_invoker = true) AS
 SELECT j.id,
    j.batch_spec_workspace_id,
    j.state,
    j.failure_message,
    j.started_at,
    j.finished_at,
    j.process_after,
    j.num_resets,
    j.num_failures,
    j.execution_logs,
    j.worker_hostname,
    j.last_heartbeat_at,
    j.created_at,
    j.updated_at,
    j.cancel,
    j.queued_at,
    j.user_id,
    j.version,
    q.place_in_global_queue,
    q.place_in_user_queue,
    j.tenant_id,
    j.changeset_hook_job_id
   FROM (batch_spec_workspace_execution_jobs j
     LEFT JOIN batch_spec_workspace_execution_queue q ON ((j.id = q.id)));
