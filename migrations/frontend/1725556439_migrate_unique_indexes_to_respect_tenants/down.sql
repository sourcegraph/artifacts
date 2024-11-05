CREATE UNIQUE INDEX tmp_unique_index ON batch_changes_site_credentials (external_service_type, external_service_id);
DROP INDEX IF EXISTS batch_changes_site_credentials_unique;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_site_credentials_unique;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON batch_specs (rand_id);
DROP INDEX IF EXISTS batch_specs_unique_rand_id;
ALTER INDEX tmp_unique_index RENAME TO batch_specs_unique_rand_id;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON changeset_specs (rand_id);
DROP INDEX IF EXISTS changeset_specs_unique_rand_id;
ALTER INDEX tmp_unique_index RENAME TO changeset_specs_unique_rand_id;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON codeintel_langugage_support_requests (user_id, language_id);
DROP INDEX IF EXISTS codeintel_langugage_support_requests_user_id_language;
ALTER INDEX tmp_unique_index RENAME TO codeintel_langugage_support_requests_user_id_language;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON event_logs_export_allowlist (event_name);
DROP INDEX IF EXISTS event_logs_export_allowlist_event_name_idx;
ALTER INDEX tmp_unique_index RENAME TO event_logs_export_allowlist_event_name_idx;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON executor_secrets (key, scope) WHERE namespace_user_id IS NULL AND namespace_org_id IS NULL;
DROP INDEX IF EXISTS executor_secrets_unique_key_global;
ALTER INDEX tmp_unique_index RENAME TO executor_secrets_unique_key_global;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON external_services (kind, cloud_default) WHERE cloud_default = true AND deleted_at IS NULL;
DROP INDEX IF EXISTS kind_cloud_default;
ALTER INDEX tmp_unique_index RENAME TO kind_cloud_default;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON github_apps (app_id, slug, base_url);
DROP INDEX IF EXISTS github_apps_app_id_slug_base_url_unique;
ALTER INDEX tmp_unique_index RENAME TO github_apps_app_id_slug_base_url_unique;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON orgs (name) WHERE deleted_at IS NULL;
DROP INDEX IF EXISTS orgs_name;
ALTER INDEX tmp_unique_index RENAME TO orgs_name;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON own_signal_configurations (name);
DROP INDEX IF EXISTS own_signal_configurations_name_uidx;
ALTER INDEX tmp_unique_index RENAME TO own_signal_configurations_name_uidx;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON permission_sync_jobs (priority, user_id, repository_id, cancel, process_after) WHERE state = 'queued'::text;
DROP INDEX IF EXISTS permission_sync_jobs_unique;
ALTER INDEX tmp_unique_index RENAME TO permission_sync_jobs_unique;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON permissions (namespace, action);
DROP INDEX IF EXISTS permissions_unique_namespace_action;
ALTER INDEX tmp_unique_index RENAME TO permissions_unique_namespace_action;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON registry_extensions (COALESCE(publisher_user_id, 0), COALESCE(publisher_org_id, 0), name) WHERE deleted_at IS NULL;
DROP INDEX IF EXISTS registry_extensions_publisher_name;
ALTER INDEX tmp_unique_index RENAME TO registry_extensions_publisher_name;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON repo (external_service_type, external_service_id, external_id);
DROP INDEX IF EXISTS repo_external_unique_idx;
ALTER INDEX tmp_unique_index RENAME TO repo_external_unique_idx;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON roles (name);
DROP INDEX IF EXISTS unique_role_name;
ALTER INDEX tmp_unique_index RENAME TO unique_role_name;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON search_contexts (name) WHERE namespace_user_id IS NULL AND namespace_org_id IS NULL;
DROP INDEX IF EXISTS search_contexts_name_without_namespace_unique;
ALTER INDEX tmp_unique_index RENAME TO search_contexts_name_without_namespace_unique;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON teams (name);
DROP INDEX IF EXISTS teams_name;
ALTER INDEX tmp_unique_index RENAME TO teams_name;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON user_external_accounts (service_type, service_id, client_id, account_id) WHERE deleted_at IS NULL;
DROP INDEX IF EXISTS user_external_accounts_account;
ALTER INDEX tmp_unique_index RENAME TO user_external_accounts_account;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON users (billing_customer_id) WHERE deleted_at IS NULL;
DROP INDEX IF EXISTS users_billing_customer_id;
ALTER INDEX tmp_unique_index RENAME TO users_billing_customer_id;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON users (username) WHERE deleted_at IS NULL;
DROP INDEX IF EXISTS users_username;
ALTER INDEX tmp_unique_index RENAME TO users_username;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON vulnerabilities (source_id);
DROP INDEX IF EXISTS vulnerabilities_source_id;
ALTER INDEX tmp_unique_index RENAME TO vulnerabilities_source_id;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON access_requests (email) WHERE status = 'PENDING';
DROP INDEX IF EXISTS access_requests_email_key;
ALTER INDEX tmp_unique_index RENAME TO access_requests_email_key;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX IF NOT EXISTS critical_and_site_config_unique ON critical_and_site_config (id, type);

ALTER TABLE user_emails DROP CONSTRAINT IF EXISTS user_emails_unique_verified_email;
ALTER TABLE user_emails ADD CONSTRAINT user_emails_unique_verified_email EXCLUDE USING btree(email WITH OPERATOR(=)) WHERE ((verified_at IS NOT NULL AND deleted_at IS NULL));
COMMIT AND CHAIN;

CREATE UNIQUE INDEX tmp_unique_index ON lsif_dependency_repos (scheme, name);
DROP INDEX IF EXISTS lsif_dependency_repos_unique_scheme_name;
ALTER INDEX tmp_unique_index RENAME TO lsif_dependency_repos_unique_scheme_name;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX IF NOT EXISTS lsif_dependency_repos_unique_scheme_name_tnt ON lsif_dependency_repos USING btree (scheme, name, tenant_id);
COMMIT AND CHAIN;

CREATE UNIQUE INDEX IF NOT EXISTS repo_external_unique_idx_tnt ON repo USING btree (external_service_type, external_service_id, external_id, tenant_id);
COMMIT AND CHAIN;

CREATE UNIQUE INDEX IF NOT EXISTS user_external_accounts_account_tnt ON user_external_accounts USING btree (service_type, service_id, client_id, account_id, tenant_id) WHERE deleted_at IS NULL;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX IF NOT EXISTS users_billing_customer_id_tnt ON users USING btree (billing_customer_id, tenant_id) WHERE deleted_at IS NULL;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX IF NOT EXISTS users_username_tnt ON users USING btree (username, tenant_id) WHERE deleted_at IS NULL;
