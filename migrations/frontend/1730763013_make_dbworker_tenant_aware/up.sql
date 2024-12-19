CREATE POLICY isolation_policy_2 ON batch_spec_resolution_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON batch_spec_resolution_jobs;
ALTER POLICY isolation_policy_2 ON batch_spec_resolution_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON batch_spec_workspace_execution_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON batch_spec_workspace_execution_jobs;
ALTER POLICY isolation_policy_2 ON batch_spec_workspace_execution_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON changeset_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON changeset_jobs;
ALTER POLICY isolation_policy_2 ON changeset_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON cm_action_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON cm_action_jobs;
ALTER POLICY isolation_policy_2 ON cm_action_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON cm_trigger_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON cm_trigger_jobs;
ALTER POLICY isolation_policy_2 ON cm_trigger_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON context_detection_embedding_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON context_detection_embedding_jobs;
ALTER POLICY isolation_policy_2 ON context_detection_embedding_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON exhaustive_search_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON exhaustive_search_jobs;
ALTER POLICY isolation_policy_2 ON exhaustive_search_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON exhaustive_search_repo_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON exhaustive_search_repo_jobs;
ALTER POLICY isolation_policy_2 ON exhaustive_search_repo_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON exhaustive_search_repo_revision_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON exhaustive_search_repo_revision_jobs;
ALTER POLICY isolation_policy_2 ON exhaustive_search_repo_revision_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON explicit_permissions_bitbucket_projects_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON explicit_permissions_bitbucket_projects_jobs;
ALTER POLICY isolation_policy_2 ON explicit_permissions_bitbucket_projects_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON external_service_sync_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON external_service_sync_jobs;
ALTER POLICY isolation_policy_2 ON external_service_sync_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON gitserver_relocator_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON gitserver_relocator_jobs;
ALTER POLICY isolation_policy_2 ON gitserver_relocator_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON insights_query_runner_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON insights_query_runner_jobs;
ALTER POLICY isolation_policy_2 ON insights_query_runner_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON lsif_dependency_indexing_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON lsif_dependency_indexing_jobs;
ALTER POLICY isolation_policy_2 ON lsif_dependency_indexing_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON lsif_dependency_syncing_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON lsif_dependency_syncing_jobs;
ALTER POLICY isolation_policy_2 ON lsif_dependency_syncing_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON lsif_indexes USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON lsif_indexes;
ALTER POLICY isolation_policy_2 ON lsif_indexes RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON lsif_uploads USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON lsif_uploads;
ALTER POLICY isolation_policy_2 ON lsif_uploads RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON outbound_webhook_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON outbound_webhook_jobs;
ALTER POLICY isolation_policy_2 ON outbound_webhook_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON own_background_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON own_background_jobs;
ALTER POLICY isolation_policy_2 ON own_background_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON permission_sync_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON permission_sync_jobs;
ALTER POLICY isolation_policy_2 ON permission_sync_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON repo_context_stats_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON repo_context_stats_jobs;
ALTER POLICY isolation_policy_2 ON repo_context_stats_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON repo_embedding_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON repo_embedding_jobs;
ALTER POLICY isolation_policy_2 ON repo_embedding_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON repo_update_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON repo_update_jobs;
ALTER POLICY isolation_policy_2 ON repo_update_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON syntactic_scip_indexing_jobs USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON syntactic_scip_indexing_jobs;
ALTER POLICY isolation_policy_2 ON syntactic_scip_indexing_jobs RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY isolation_policy_2 ON changesets USING ((SELECT current_setting('app.current_tenant'::text) = 'workertenant') OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'workertenant')::integer AS current_tenant));
DROP POLICY tenant_isolation_policy ON changesets;
ALTER POLICY isolation_policy_2 ON changesets RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW batch_spec_workspace_execution_jobs_with_rank AS
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
       j.tenant_id
FROM batch_spec_workspace_execution_jobs j
LEFT JOIN batch_spec_workspace_execution_queue q ON j.id = q.id;
COMMIT AND CHAIN;

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
FROM external_services e
JOIN external_service_sync_jobs j ON e.id = j.external_service_id;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW gitserver_relocator_jobs_with_repo_name AS
SELECT glj.id,
       glj.state,
       glj.queued_at,
       glj.failure_message,
       glj.started_at,
       glj.finished_at,
       glj.process_after,
       glj.num_resets,
       glj.num_failures,
       glj.last_heartbeat_at,
       glj.execution_logs,
       glj.worker_hostname,
       glj.repo_id,
       glj.source_hostname,
       glj.dest_hostname,
       glj.delete_source,
       r.name AS repo_name,
       glj.tenant_id
FROM gitserver_relocator_jobs glj
JOIN repo r ON r.id = glj.repo_id;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW lsif_dumps AS
SELECT u.id,
       u.commit,
       u.root,
       u.queued_at,
       u.uploaded_at,
       u.state,
       u.failure_message,
       u.started_at,
       u.finished_at,
       u.repository_id,
       u.indexer,
       u.indexer_version,
       u.num_parts,
       u.uploaded_parts,
       u.process_after,
       u.num_resets,
       u.upload_size,
       u.num_failures,
       u.associated_index_id,
       u.expired,
       u.last_retention_scan_at,
       u.finished_at AS processed_at,
       u.tenant_id
FROM lsif_uploads u
WHERE u.state = 'completed'::text
  OR u.state = 'deleting'::text;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW lsif_dumps_with_repository_name AS
SELECT u.id,
       u.commit,
       u.root,
       u.queued_at,
       u.uploaded_at,
       u.state,
       u.failure_message,
       u.started_at,
       u.finished_at,
       u.repository_id,
       u.indexer,
       u.indexer_version,
       u.num_parts,
       u.uploaded_parts,
       u.process_after,
       u.num_resets,
       u.upload_size,
       u.num_failures,
       u.associated_index_id,
       u.expired,
       u.last_retention_scan_at,
       u.processed_at,
       r.name AS repository_name,
       u.tenant_id
FROM lsif_dumps u
JOIN repo r ON r.id = u.repository_id
WHERE r.deleted_at IS NULL;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW lsif_uploads_with_repository_name AS
SELECT u.id,
       u.commit,
       u.root,
       u.queued_at,
       u.uploaded_at,
       u.state,
       u.failure_message,
       u.started_at,
       u.finished_at,
       u.repository_id,
       u.indexer,
       u.indexer_version,
       u.num_parts,
       u.uploaded_parts,
       u.process_after,
       u.num_resets,
       u.upload_size,
       u.num_failures,
       u.associated_index_id,
       u.content_type,
       u.should_reindex,
       u.expired,
       u.last_retention_scan_at,
       r.name AS repository_name,
       u.uncompressed_size,
       u.tenant_id
FROM lsif_uploads u
JOIN repo r ON r.id = u.repository_id
WHERE r.deleted_at IS NULL;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW own_background_jobs_config_aware AS
SELECT obj.id,
       obj.state,
       obj.failure_message,
       obj.queued_at,
       obj.started_at,
       obj.finished_at,
       obj.process_after,
       obj.num_resets,
       obj.num_failures,
       obj.last_heartbeat_at,
       obj.execution_logs,
       obj.worker_hostname,
       obj.cancel,
       obj.repo_id,
       obj.job_type,
       osc.name AS config_name,
       obj.tenant_id
FROM own_background_jobs obj
JOIN own_signal_configurations osc ON obj.job_type = osc.id
WHERE osc.enabled IS TRUE;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW lsif_indexes_with_repository_name AS
SELECT u.id,
       u.commit,
       u.queued_at,
       u.state,
       u.failure_message,
       u.started_at,
       u.finished_at,
       u.repository_id,
       u.process_after,
       u.num_resets,
       u.num_failures,
       u.docker_steps,
       u.root,
       u.indexer,
       u.indexer_args,
       u.outfile,
       u.log_contents,
       u.execution_logs,
       u.local_steps,
       u.should_reindex,
       u.requested_envvars,
       r.name AS repository_name,
       u.enqueuer_user_id,
       u.tenant_id
FROM lsif_indexes u
JOIN repo r ON r.id = u.repository_id
WHERE r.deleted_at IS NULL;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW syntactic_scip_indexing_jobs_with_repository_name AS
SELECT u.id,
       u.commit,
       u.queued_at,
       u.state,
       u.failure_message,
       u.started_at,
       u.finished_at,
       u.repository_id,
       u.process_after,
       u.num_resets,
       u.num_failures,
       u.execution_logs,
       u.should_reindex,
       u.enqueuer_user_id,
       r.name AS repository_name,
       u.tenant_id
FROM syntactic_scip_indexing_jobs u
JOIN repo r ON r.id = u.repository_id
WHERE r.deleted_at IS NULL;
COMMIT AND CHAIN;

CREATE OR REPLACE VIEW reconciler_changesets AS
SELECT c.id,
    c.batch_change_ids,
    c.repo_id,
    c.queued_at,
    c.created_at,
    c.updated_at,
    c.metadata,
    c.external_id,
    c.external_service_type,
    c.external_deleted_at,
    c.external_branch,
    c.external_updated_at,
    c.external_state,
    c.external_review_state,
    c.external_check_state,
    c.commit_verification,
    c.diff_stat_added,
    c.diff_stat_deleted,
    c.sync_state,
    c.current_spec_id,
    c.previous_spec_id,
    c.publication_state,
    c.owned_by_batch_change_id,
    c.reconciler_state,
    c.computed_state,
    c.failure_message,
    c.started_at,
    c.finished_at,
    c.process_after,
    c.num_resets,
    c.closing,
    c.num_failures,
    c.log_contents,
    c.execution_logs,
    c.syncer_error,
    c.external_title,
    c.worker_hostname,
    c.ui_publication_state,
    c.last_heartbeat_at,
    c.external_fork_name,
    c.external_fork_namespace,
    c.detached_at,
    c.previous_failure_message,
    c.tenant_id
   FROM (changesets c
     JOIN repo r ON ((r.id = c.repo_id)))
  WHERE ((r.deleted_at IS NULL) AND (EXISTS ( SELECT 1
           FROM ((batch_changes
             LEFT JOIN users namespace_user ON ((batch_changes.namespace_user_id = namespace_user.id)))
             LEFT JOIN orgs namespace_org ON ((batch_changes.namespace_org_id = namespace_org.id)))
          WHERE ((c.batch_change_ids ? (batch_changes.id)::text) AND (namespace_user.deleted_at IS NULL) AND (namespace_org.deleted_at IS NULL)))));
