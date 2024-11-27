-- If an instance pg_upgrades from 12 to 16 we get a different schema than a
-- fresh installation on 16 (which is how our schema files are generated).
-- This migration redefines these definitions such that a pg_upgraded instance
-- reports the same schema.

-- NOTE: after each schema change we run COMMIT AND CHAIN to avoid a
-- transaction linking many different objects.

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
SELECT id,
       row_number() OVER () AS place_in_global_queue,
       place_in_user_queue
FROM queue_candidates;

COMMIT AND CHAIN;

CREATE OR REPLACE VIEW codeintel_configuration_policies AS
SELECT id,
       repository_id,
       name,
       type,
       pattern,
       retention_enabled,
       retention_duration_hours,
       retain_intermediate_commits,
       indexing_enabled,
       index_commit_max_age_hours,
       index_intermediate_commits,
       protected,
       repository_patterns,
       last_resolved_at,
       embeddings_enabled
FROM lsif_configuration_policies;

COMMIT AND CHAIN;

CREATE OR REPLACE VIEW codeintel_configuration_policies_repository_pattern_lookup AS
SELECT policy_id,
       repo_id
FROM lsif_configuration_policies_repository_pattern_lookup;

COMMIT AND CHAIN;

CREATE OR REPLACE VIEW lsif_dumps AS
SELECT id,
       commit,
       root,
       queued_at,
       uploaded_at,
       state,
       failure_message,
       started_at,
       finished_at,
       repository_id,
       indexer,
       indexer_version,
       num_parts,
       uploaded_parts,
       process_after,
       num_resets,
       upload_size,
       num_failures,
       associated_index_id,
       expired,
       last_retention_scan_at,
       finished_at AS processed_at
FROM lsif_uploads u
WHERE ((state = 'completed'::text) OR (state = 'deleting'::text));

COMMIT AND CHAIN;

CREATE OR REPLACE VIEW outbound_webhooks_with_event_types AS
SELECT id,
       created_by,
       created_at,
       updated_by,
       updated_at,
       encryption_key_id,
       url,
       secret,
       array_to_json(ARRAY(SELECT json_build_object('id', outbound_webhook_event_types.id, 'outbound_webhook_id',
                                                    outbound_webhook_event_types.outbound_webhook_id, 'event_type',
                                                    outbound_webhook_event_types.event_type, 'scope',
                                                    outbound_webhook_event_types.scope) AS json_build_object
                           FROM outbound_webhook_event_types
                           WHERE (outbound_webhook_event_types.outbound_webhook_id = outbound_webhooks.id))) AS event_types
FROM outbound_webhooks;

COMMIT AND CHAIN;

CREATE OR REPLACE VIEW site_config AS
SELECT site_id,
       initialized
FROM global_state;

COMMIT AND CHAIN;

ALTER TABLE webhooks
    ALTER COLUMN uuid SET DEFAULT public.gen_random_uuid();

COMMIT AND CHAIN;

DROP INDEX IF EXISTS gitserver_repos_schedule_order_idx;
CREATE INDEX gitserver_repos_schedule_order_idx ON gitserver_repos USING btree (
    (timezone('UTC'::text, last_fetch_attempt_at) + LEAST(GREATEST((last_fetched - last_changed) / 2::double precision * (failed_fetch_attempts + 1)::double precision, '00:00:45'::interval), '08:00:00'::interval)) DESC,
    repo_id
);
