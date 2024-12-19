CREATE OR REPLACE VIEW external_service_sync_jobs_with_next_sync_at AS
 SELECT j.id,
    j.state,
    j.failure_message,
    j.queued_at,
    j.started_at,
    j.finished_at,
    j.process_after,
    j.num_resets,
    j.num_failures,
    j.execution_logs,
    j.external_service_id,
    e.next_sync_at,
    e.tenant_id
   FROM (external_services e
     JOIN external_service_sync_jobs j ON ((e.id = j.external_service_id)));
