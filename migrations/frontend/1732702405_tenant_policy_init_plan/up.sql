-- This migration updates our tenant_isolation_policy such that we can
-- evaluate app.current_tenant once in the init plan. Additionally we move to
-- using a single policy name for all tables.

CREATE OR REPLACE FUNCTION migrate_tenant_policy_init_plan_frontend(table_name text)
RETURNS void AS $$
BEGIN
    EXECUTE format('CREATE POLICY tenant_isolation_policy_new ON %I USING (tenant_id = (SELECT current_setting(''app.current_tenant''::text)::integer AS current_tenant))', table_name);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_policy ON %I', table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I_isolation_policy ON %I', table_name, table_name);
    EXECUTE format('ALTER POLICY tenant_isolation_policy_new ON %I RENAME TO tenant_isolation_policy', table_name);
END;
$$ LANGUAGE plpgsql;

SELECT migrate_tenant_policy_init_plan_frontend('access_requests'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('access_tokens'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('aggregated_user_statistics'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('assigned_owners'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('assigned_teams'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_changes'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_changes_site_credentials'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_spec_execution_cache_entries'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_spec_resolution_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_spec_workspace_execution_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_spec_workspace_execution_last_dequeues'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_spec_workspace_files'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_spec_workspaces'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('batch_specs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cached_available_indexers'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('changeset_events'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('changeset_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('changeset_specs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('changesets'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_action_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_emails'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_last_searched'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_monitors'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_queries'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_recipients'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_slack_webhooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_trigger_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cm_webhooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('code_hosts'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('codeintel_autoindex_queue'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('codeintel_autoindexing_exceptions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('codeintel_commit_dates'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('codeintel_inference_scripts'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('codeintel_langugage_support_requests'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('codeowners_individual_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('codeowners'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('codeowners_owners'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('cody_audit_log'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('commit_authors'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('configuration_policies_audit_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('context_detection_embedding_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('discussion_comments'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('discussion_mail_reply_tokens'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('discussion_threads'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('discussion_threads_target_repo'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('event_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('event_logs_scrape_state'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('event_logs_scrape_state_own'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('executor_heartbeats'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('executor_job_tokens'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('executor_secret_access_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('executor_secrets'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('exhaustive_search_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('exhaustive_search_repo_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('exhaustive_search_repo_revision_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('explicit_permissions_bitbucket_projects_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('external_service_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('external_service_sync_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('external_services'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('feature_flag_overrides'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('feature_flags'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('github_app_installs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('github_apps'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('gitserver_relocator_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('gitserver_repos_statistics'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('gitserver_repos_sync_output'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('global_state'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('insights_query_runner_jobs_dependencies'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('insights_query_runner_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('insights_settings_migration_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_configuration_policies'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_configuration_policies_repository_pattern_lookup'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_dependency_indexing_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_dependency_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_dependency_syncing_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_dirty_repositories'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_index_configuration'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_indexes'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_last_index_scan'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_last_retention_scan'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_nearest_uploads'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_nearest_uploads_links'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_packages'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_references'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_retention_configuration'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_uploads_audit_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_uploads'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_uploads_reference_counts'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_uploads_visible_at_tip'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('lsif_uploads_vulnerability_scan'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('names'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('namespace_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('notebook_stars'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('notebooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('org_invitations'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('org_members'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('org_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('orgs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('out_of_band_migrations_errors'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('outbound_webhook_event_types'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('outbound_webhook_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('outbound_webhook_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('outbound_webhooks'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('own_aggregate_recent_contribution'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('own_aggregate_recent_view'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('own_background_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('own_signal_configurations'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('own_signal_recent_contribution'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('ownership_path_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('package_repo_filters'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('package_repo_versions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('permission_sync_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('phabricator_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('prompts'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('query_runner_state'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('registry_extension_releases'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('registry_extensions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_commits_changelists'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_context_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_context_stats_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_embedding_job_stats'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_embedding_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_kvps'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_paths'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_pending_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_statistics'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('repo_update_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('role_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('roles'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('saved_searches'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('search_context_default'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('search_context_repos'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('search_context_stars'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('search_contexts'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('security_event_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('settings'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('sub_repo_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('survey_responses'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('syntactic_scip_indexing_jobs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('syntactic_scip_last_index_scan'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('team_members'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('teams'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('telemetry_events_export_queue'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('temporary_settings'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('user_credentials'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('user_emails'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('user_external_accounts'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('user_onboarding_tour'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('user_pending_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('user_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('user_repo_permissions'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('user_roles'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('users'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('vulnerabilities'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('vulnerability_affected_packages'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('vulnerability_affected_symbols'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('vulnerability_matches'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('webhook_logs'); COMMIT AND CHAIN;
SELECT migrate_tenant_policy_init_plan_frontend('webhooks'); COMMIT AND CHAIN;

-- The following tables allow zoekttenant to access the whole table.
CREATE POLICY tenant_isolation_policy_new ON gitserver_repos USING ((
    (SELECT current_setting('app.current_tenant'::text) = 'zoekttenant')
    OR
    (tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant')::integer AS current_tenant))
));
DROP POLICY IF EXISTS tenant_isolation_policy ON gitserver_repos;
DROP POLICY IF EXISTS gitserver_repos_isolation_policy ON gitserver_repos;
ALTER POLICY tenant_isolation_policy_new ON gitserver_repos RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY tenant_isolation_policy_new ON repo USING ((
    (SELECT current_setting('app.current_tenant'::text) = 'zoekttenant')
    OR
    (tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant')::integer AS current_tenant))
));
DROP POLICY IF EXISTS tenant_isolation_policy ON repo;
DROP POLICY IF EXISTS repo_isolation_policy ON repo;
ALTER POLICY tenant_isolation_policy_new ON repo RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

CREATE POLICY tenant_isolation_policy_new ON zoekt_repos USING ((
    (SELECT current_setting('app.current_tenant'::text) = 'zoekttenant')
    OR
    (tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant')::integer AS current_tenant))
));
DROP POLICY IF EXISTS tenant_isolation_policy ON zoekt_repos;
DROP POLICY IF EXISTS zoekt_repos_isolation_policy ON zoekt_repos;
ALTER POLICY tenant_isolation_policy_new ON zoekt_repos RENAME TO tenant_isolation_policy;
COMMIT AND CHAIN;

DROP FUNCTION migrate_tenant_policy_init_plan_frontend(text);
