CREATE OR REPLACE VIEW batch_spec_workspace_execution_queue AS
WITH queue_candidates AS (SELECT exec.id,
                                 rank()
                                 OVER (PARTITION BY queue.user_id ORDER BY exec.created_at, exec.id) AS place_in_user_queue
                          FROM (batch_spec_workspace_execution_jobs exec
                              JOIN batch_spec_workspace_execution_last_dequeues queue
                                ON ((queue.user_id = exec.user_id)))
                          WHERE (exec.state = 'queued'::text)
                          ORDER BY (rank() OVER (PARTITION BY queue.user_id ORDER BY exec.created_at, exec.id)),
                                   queue.latest_dequeue NULLS FIRST)
SELECT queue_candidates.id,
       row_number() OVER () AS place_in_global_queue,
       queue_candidates.place_in_user_queue
FROM queue_candidates;

CREATE OR REPLACE VIEW codeintel_configuration_policies AS
SELECT lsif_configuration_policies.id,
       lsif_configuration_policies.repository_id,
       lsif_configuration_policies.name,
       lsif_configuration_policies.type,
       lsif_configuration_policies.pattern,
       lsif_configuration_policies.retention_enabled,
       lsif_configuration_policies.retention_duration_hours,
       lsif_configuration_policies.retain_intermediate_commits,
       lsif_configuration_policies.indexing_enabled,
       lsif_configuration_policies.index_commit_max_age_hours,
       lsif_configuration_policies.index_intermediate_commits,
       lsif_configuration_policies.protected,
       lsif_configuration_policies.repository_patterns,
       lsif_configuration_policies.last_resolved_at,
       lsif_configuration_policies.embeddings_enabled
FROM lsif_configuration_policies;

CREATE OR REPLACE VIEW codeintel_configuration_policies_repository_pattern_lookup AS
SELECT lsif_configuration_policies_repository_pattern_lookup.policy_id,
       lsif_configuration_policies_repository_pattern_lookup.repo_id
FROM lsif_configuration_policies_repository_pattern_lookup;

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
       u.finished_at AS processed_at
FROM lsif_uploads u
WHERE ((u.state = 'completed'::text) OR (u.state = 'deleting'::text));

CREATE OR REPLACE VIEW outbound_webhooks_with_event_types AS
SELECT outbound_webhooks.id,
       outbound_webhooks.created_by,
       outbound_webhooks.created_at,
       outbound_webhooks.updated_by,
       outbound_webhooks.updated_at,
       outbound_webhooks.encryption_key_id,
       outbound_webhooks.url,
       outbound_webhooks.secret,
       array_to_json(ARRAY(SELECT json_build_object('id', outbound_webhook_event_types.id, 'outbound_webhook_id',
                                                    outbound_webhook_event_types.outbound_webhook_id, 'event_type',
                                                    outbound_webhook_event_types.event_type, 'scope',
                                                    outbound_webhook_event_types.scope) AS json_build_object
                           FROM outbound_webhook_event_types
                           WHERE (outbound_webhook_event_types.outbound_webhook_id = outbound_webhooks.id))) AS event_types
FROM outbound_webhooks;

CREATE OR REPLACE VIEW site_config AS
SELECT global_state.site_id,
       global_state.initialized
FROM global_state;

ALTER TABLE webhooks
    ALTER COLUMN uuid SET DEFAULT gen_random_uuid();

DROP INDEX IF EXISTS gitserver_repos_schedule_order_idx;
CREATE INDEX gitserver_repos_schedule_order_idx ON gitserver_repos USING btree (
    ((last_fetch_attempt_at AT TIME ZONE 'UTC'::text) + LEAST(GREATEST((last_fetched - last_changed) / 2::double precision * (failed_fetch_attempts + 1)::double precision, '00:00:45'::interval), '08:00:00'::interval)) DESC,
    repo_id
);
