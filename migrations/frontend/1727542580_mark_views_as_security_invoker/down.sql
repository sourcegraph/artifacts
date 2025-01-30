ALTER VIEW batch_spec_workspace_execution_queue RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW batch_spec_workspace_execution_jobs_with_rank RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW branch_changeset_specs_and_changesets RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW codeintel_configuration_policies RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW codeintel_configuration_policies_repository_pattern_lookup RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW gitserver_relocator_jobs_with_repo_name RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW lsif_dumps RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW lsif_dumps_with_repository_name RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW lsif_uploads_with_repository_name RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW outbound_webhooks_with_event_types RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW own_background_jobs_config_aware RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW reconciler_changesets RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW tracking_changeset_specs_and_changesets RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW site_config RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW lsif_indexes_with_repository_name RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW syntactic_scip_indexing_jobs_with_repository_name RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW prompts_view RESET (security_invoker);
