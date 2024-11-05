-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON batch_changes_site_credentials (external_service_type, external_service_id, tenant_id);
DROP INDEX IF EXISTS batch_changes_site_credentials_unique;
ALTER INDEX tmp_unique_index RENAME TO batch_changes_site_credentials_unique;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON batch_specs (rand_id, tenant_id);
DROP INDEX IF EXISTS batch_specs_unique_rand_id;
ALTER INDEX tmp_unique_index RENAME TO batch_specs_unique_rand_id;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON changeset_specs (rand_id, tenant_id);
DROP INDEX IF EXISTS changeset_specs_unique_rand_id;
ALTER INDEX tmp_unique_index RENAME TO changeset_specs_unique_rand_id;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON codeintel_langugage_support_requests (user_id, language_id, tenant_id);
DROP INDEX IF EXISTS codeintel_langugage_support_requests_user_id_language;
ALTER INDEX tmp_unique_index RENAME TO codeintel_langugage_support_requests_user_id_language;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON event_logs_export_allowlist (event_name, tenant_id);
DROP INDEX IF EXISTS event_logs_export_allowlist_event_name_idx;
ALTER INDEX tmp_unique_index RENAME TO event_logs_export_allowlist_event_name_idx;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON executor_secrets (key, scope, tenant_id) WHERE namespace_user_id IS NULL AND namespace_org_id IS NULL;
DROP INDEX IF EXISTS executor_secrets_unique_key_global;
ALTER INDEX tmp_unique_index RENAME TO executor_secrets_unique_key_global;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON external_services (kind, cloud_default, tenant_id) WHERE cloud_default = true AND deleted_at IS NULL;
DROP INDEX IF EXISTS kind_cloud_default;
ALTER INDEX tmp_unique_index RENAME TO kind_cloud_default;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON github_apps (app_id, slug, base_url, tenant_id);
DROP INDEX IF EXISTS github_apps_app_id_slug_base_url_unique;
ALTER INDEX tmp_unique_index RENAME TO github_apps_app_id_slug_base_url_unique;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON orgs (name, tenant_id) WHERE deleted_at IS NULL;
DROP INDEX IF EXISTS orgs_name;
ALTER INDEX tmp_unique_index RENAME TO orgs_name;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON own_signal_configurations (name, tenant_id);
DROP INDEX IF EXISTS own_signal_configurations_name_uidx;
ALTER INDEX tmp_unique_index RENAME TO own_signal_configurations_name_uidx;
COMMIT AND CHAIN;

-- Should be small enough.
-- TODO: Does this work at all? user_id and repo_id are nullable.
CREATE UNIQUE INDEX tmp_unique_index ON permission_sync_jobs (priority, user_id, repository_id, cancel, process_after, tenant_id) WHERE state = 'queued'::text;
DROP INDEX IF EXISTS permission_sync_jobs_unique;
ALTER INDEX tmp_unique_index RENAME TO permission_sync_jobs_unique;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON permissions (namespace, action, tenant_id);
DROP INDEX IF EXISTS permissions_unique_namespace_action;
ALTER INDEX tmp_unique_index RENAME TO permissions_unique_namespace_action;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON registry_extensions (COALESCE(publisher_user_id, 0), COALESCE(publisher_org_id, 0), name, tenant_id) WHERE deleted_at IS NULL;
DROP INDEX IF EXISTS registry_extensions_publisher_name;
ALTER INDEX tmp_unique_index RENAME TO registry_extensions_publisher_name;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON roles (name, tenant_id);
DROP INDEX IF EXISTS unique_role_name;
ALTER INDEX tmp_unique_index RENAME TO unique_role_name;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON search_contexts (name, tenant_id) WHERE namespace_user_id IS NULL AND namespace_org_id IS NULL;
DROP INDEX IF EXISTS search_contexts_name_without_namespace_unique;
ALTER INDEX tmp_unique_index RENAME TO search_contexts_name_without_namespace_unique;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON teams (name, tenant_id);
DROP INDEX IF EXISTS teams_name;
ALTER INDEX tmp_unique_index RENAME TO teams_name;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON vulnerabilities (source_id, tenant_id);
DROP INDEX IF EXISTS vulnerabilities_source_id;
ALTER INDEX tmp_unique_index RENAME TO vulnerabilities_source_id;
COMMIT AND CHAIN;

-- Should be small enough.
CREATE UNIQUE INDEX tmp_unique_index ON access_requests (email, tenant_id) WHERE status = 'PENDING';
DROP INDEX IF EXISTS access_requests_email_key;
ALTER INDEX tmp_unique_index RENAME TO access_requests_email_key;
COMMIT AND CHAIN;

-- This index used to be used when we had critical AND site configs, but we no longer, so instead of fixing
-- it forward we're simply dropping it.
DROP INDEX IF EXISTS critical_and_site_config_unique;
COMMIT AND CHAIN;

--                       table_name                       |    size    | tuple_count
-- -------------------------------------------------------+------------+-------------
--  repo                                                  | 43 GB      |     3442994
DO
$$
BEGIN
    IF to_regclass('repo_external_unique_idx_tnt') IS NOT NULL THEN
        DROP INDEX IF EXISTS repo_external_unique_idx;
        ALTER INDEX repo_external_unique_idx_tnt RENAME TO repo_external_unique_idx;
   END IF;
END
$$;
COMMIT AND CHAIN;

--                       table_name                       |    size    | tuple_count
-- -------------------------------------------------------+------------+-------------
--  user_external_accounts                                | 3145 MB    |      655048
DO
$$
BEGIN
    IF to_regclass('user_external_accounts_account_tnt') IS NOT NULL THEN
        DROP INDEX IF EXISTS user_external_accounts_account;
        ALTER INDEX user_external_accounts_account_tnt RENAME TO user_external_accounts_account;
   END IF;
END
$$;
COMMIT AND CHAIN;

--                       table_name                       |    size    | tuple_count
-- -------------------------------------------------------+------------+-------------
--  users                                                 | 373 MB     |      932939
DO
$$
BEGIN
    IF to_regclass('users_billing_customer_id_tnt') IS NOT NULL THEN
        DROP INDEX IF EXISTS users_billing_customer_id;
        ALTER INDEX users_billing_customer_id_tnt RENAME TO users_billing_customer_id;
   END IF;
END
$$;
COMMIT AND CHAIN;

--                       table_name                       |    size    | tuple_count
-- -------------------------------------------------------+------------+-------------
--  users                                                 | 373 MB     |      932939
DO
$$
BEGIN
    IF to_regclass('users_username_tnt') IS NOT NULL THEN
        DROP INDEX IF EXISTS users_username;
        ALTER INDEX users_username_tnt RENAME TO users_username;
   END IF;
END
$$;
COMMIT AND CHAIN;

ALTER TABLE user_emails DROP CONSTRAINT IF EXISTS user_emails_unique_verified_email;
ALTER TABLE user_emails ADD CONSTRAINT user_emails_unique_verified_email EXCLUDE USING btree(email WITH OPERATOR(=), tenant_id WITH OPERATOR(=)) WHERE ((verified_at IS NOT NULL AND deleted_at IS NULL));
COMMIT AND CHAIN;

DO
$$
BEGIN
    IF to_regclass('lsif_dependency_repos_unique_scheme_name_tnt') IS NOT NULL THEN
        DROP INDEX IF EXISTS lsif_dependency_repos_unique_scheme_name;
        ALTER INDEX lsif_dependency_repos_unique_scheme_name_tnt RENAME TO lsif_dependency_repos_unique_scheme_name;
   END IF;
END
$$;
