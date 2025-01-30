ALTER VIEW batch_spec_workspace_execution_queue SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW batch_spec_workspace_execution_jobs_with_rank SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW branch_changeset_specs_and_changesets SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW codeintel_configuration_policies SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW codeintel_configuration_policies_repository_pattern_lookup SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW gitserver_relocator_jobs_with_repo_name SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW lsif_dumps SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW lsif_dumps_with_repository_name SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW lsif_uploads_with_repository_name SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW outbound_webhooks_with_event_types SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW own_background_jobs_config_aware SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW reconciler_changesets SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW tracking_changeset_specs_and_changesets SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW site_config SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW lsif_indexes_with_repository_name SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW syntactic_scip_indexing_jobs_with_repository_name SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW prompts_view SET (security_invoker = TRUE);
