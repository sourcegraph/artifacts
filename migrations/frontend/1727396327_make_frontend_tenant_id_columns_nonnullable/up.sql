CREATE UNIQUE INDEX tmp_unique_index ON batch_changes (name, namespace_org_id) WHERE namespace_org_id IS NOT NULL;
DROP INDEX IF EXISTS batch_changes_unique_org_id;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_unique_org_id;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON batch_changes (name, namespace_user_id) WHERE namespace_user_id IS NOT NULL;
DROP INDEX IF EXISTS batch_changes_unique_user_id;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_unique_user_id;
COMMIT AND CHAIN;

ALTER TABLE discussion_mail_reply_tokens DROP CONSTRAINT IF EXISTS discussion_mail_reply_tokens_pkey;
ALTER TABLE discussion_mail_reply_tokens ADD CONSTRAINT discussion_mail_reply_tokens_pkey PRIMARY KEY (token);
COMMIT AND CHAIN;

ALTER TABLE feature_flags DROP CONSTRAINT IF EXISTS feature_flags_pkey;
ALTER TABLE feature_flags ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (flag_name);
COMMIT AND CHAIN;

ALTER TABLE names DROP CONSTRAINT IF EXISTS names_pkey;
ALTER TABLE names ADD CONSTRAINT names_pkey PRIMARY KEY (name);
COMMIT AND CHAIN;

ALTER TABLE syntactic_scip_last_index_scan DROP CONSTRAINT IF EXISTS syntactic_scip_last_index_scan_pkey;
ALTER TABLE syntactic_scip_last_index_scan ADD CONSTRAINT syntactic_scip_last_index_scan_pkey PRIMARY KEY (repository_id);
COMMIT AND CHAIN;

CREATE OR REPLACE FUNCTION migrate_tenant_id_non_null_frontend(table_name text)
RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I DROP COLUMN IF EXISTS tenant_id;', table_name);
    EXECUTE format('ALTER TABLE %I ADD COLUMN tenant_id integer NOT NULL DEFAULT 1;', table_name);
    EXECUTE format('ALTER TABLE %I ALTER COLUMN tenant_id SET DEFAULT (current_setting(''app.current_tenant''::text))::integer;', table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_tenant_id_non_null_frontend('access_requests'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('access_tokens'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('aggregated_user_statistics'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('assigned_owners'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('assigned_teams'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_changes_site_credentials'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_spec_execution_cache_entries'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_spec_resolution_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_spec_workspace_execution_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_spec_workspace_execution_last_dequeues'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_spec_workspace_files'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_spec_workspaces'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_specs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cached_available_indexers'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('changeset_events'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('changeset_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('changeset_specs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('changesets'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_action_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_emails'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_last_searched'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_monitors'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_queries'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_recipients'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_slack_webhooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_trigger_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('cm_webhooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('code_hosts'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('codeintel_autoindex_queue'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('codeintel_autoindexing_exceptions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('codeowners'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('codeowners_individual_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('codeowners_owners'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('commit_authors'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('context_detection_embedding_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('discussion_comments'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('discussion_threads'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('discussion_threads_target_repo'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('event_logs_export_allowlist'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('event_logs_scrape_state'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('event_logs_scrape_state_own'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('executor_heartbeats'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('executor_job_tokens'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('executor_secret_access_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('executor_secrets'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('exhaustive_search_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('exhaustive_search_repo_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('exhaustive_search_repo_revision_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('explicit_permissions_bitbucket_projects_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('external_services'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('github_app_installs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('github_apps'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('gitserver_relocator_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('gitserver_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('gitserver_repos_sync_output'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('global_state'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('insights_query_runner_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('insights_query_runner_jobs_dependencies'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_configuration_policies'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_configuration_policies_repository_pattern_lookup'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_dependency_indexing_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_dependency_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_dependency_syncing_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_dirty_repositories'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_index_configuration'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_indexes'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_last_retention_scan'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_packages'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_retention_configuration'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_uploads'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_uploads_vulnerability_scan'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('namespace_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('notebook_stars'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('notebooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('org_invitations'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('org_members'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('org_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('orgs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('out_of_band_migrations_errors'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('outbound_webhook_event_types'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('outbound_webhook_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('outbound_webhook_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('outbound_webhooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('own_aggregate_recent_contribution'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('own_aggregate_recent_view'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('own_background_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('own_signal_configurations'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('own_signal_recent_contribution'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('ownership_path_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('package_repo_filters'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('package_repo_versions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('permission_sync_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('phabricator_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('prompts'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('registry_extension_releases'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('registry_extensions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_commits_changelists'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_context_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_context_stats_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_embedding_job_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_embedding_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_kvps'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_paths'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('role_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('roles'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('saved_searches'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('search_context_default'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('search_context_stars'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('search_contexts'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('settings'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('survey_responses'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('syntactic_scip_indexing_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('team_members'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('teams'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('telemetry_events_export_queue'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('temporary_settings'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('user_credentials'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('user_external_accounts'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('user_onboarding_tour'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('user_repo_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('user_roles'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('users'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('vulnerabilities'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('vulnerability_affected_packages'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('vulnerability_affected_symbols'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('vulnerability_matches'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('webhook_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('webhooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('zoekt_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_pending_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('search_context_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('user_emails'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_uploads_reference_counts'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('external_service_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('external_service_sync_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('sub_repo_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('codeintel_commit_dates'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('codeintel_inference_scripts'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('codeintel_langugage_support_requests'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('configuration_policies_audit_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('event_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('feature_flag_overrides'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('gitserver_repos_statistics'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('insights_settings_migration_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_last_index_scan'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_nearest_uploads'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_nearest_uploads_links'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_references'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_uploads_audit_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('lsif_uploads_visible_at_tip'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('query_runner_state'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('repo_statistics'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('security_event_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('user_pending_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('user_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('batch_changes'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('discussion_mail_reply_tokens'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('feature_flags'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('names'); COMMIT AND CHAIN;
SELECT migrate_tenant_id_non_null_frontend('syntactic_scip_last_index_scan'); COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON batch_changes (name, namespace_org_id, tenant_id) WHERE namespace_org_id IS NOT NULL;
DROP INDEX IF EXISTS batch_changes_unique_org_id;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_unique_org_id;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON batch_changes (name, namespace_user_id, tenant_id) WHERE namespace_user_id IS NOT NULL;
DROP INDEX IF EXISTS batch_changes_unique_user_id;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_unique_user_id;
COMMIT AND CHAIN;

ALTER TABLE discussion_mail_reply_tokens DROP CONSTRAINT IF EXISTS discussion_mail_reply_tokens_pkey;
ALTER TABLE discussion_mail_reply_tokens ADD PRIMARY KEY (token, tenant_id);
COMMIT AND CHAIN;

ALTER TABLE feature_flags DROP CONSTRAINT IF EXISTS feature_flags_pkey;
ALTER TABLE feature_flags ADD PRIMARY KEY (flag_name, tenant_id);
COMMIT AND CHAIN;

ALTER TABLE names DROP CONSTRAINT IF EXISTS names_pkey;
ALTER TABLE names ADD PRIMARY KEY (name, tenant_id);
COMMIT AND CHAIN;

ALTER TABLE syntactic_scip_last_index_scan DROP CONSTRAINT IF EXISTS syntactic_scip_last_index_scan_pkey;
ALTER TABLE syntactic_scip_last_index_scan ADD PRIMARY KEY (repository_id, tenant_id);
COMMIT AND CHAIN;

DO $$
BEGIN
  BEGIN
    ALTER TABLE global_state ADD CONSTRAINT global_state_site_id_unique UNIQUE (site_id, tenant_id);
  EXCEPTION
    WHEN duplicate_table THEN  -- postgres raises duplicate_table at surprising times. Ex.: for UNIQUE constraints.
    WHEN duplicate_object THEN
      RAISE NOTICE 'Table constraint global_state_site_id_unique already exists, skipping';
  END;
END $$;
COMMIT AND CHAIN;

DROP FUNCTION migrate_tenant_id_non_null_frontend(text);
