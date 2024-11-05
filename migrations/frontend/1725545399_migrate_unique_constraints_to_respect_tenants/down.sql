ALTER TABLE access_tokens ADD CONSTRAINT temp_unique_index UNIQUE(value_sha256);
ALTER TABLE access_tokens DROP CONSTRAINT IF EXISTS access_tokens_value_sha256_key;
ALTER TABLE access_tokens RENAME CONSTRAINT temp_unique_index TO access_tokens_value_sha256_key;
COMMIT AND CHAIN;

ALTER TABLE executor_heartbeats ADD CONSTRAINT temp_unique_index UNIQUE(hostname);
ALTER TABLE executor_heartbeats DROP CONSTRAINT IF EXISTS executor_heartbeats_hostname_key;
ALTER TABLE executor_heartbeats RENAME CONSTRAINT temp_unique_index TO executor_heartbeats_hostname_key;
COMMIT AND CHAIN;

ALTER TABLE executor_job_tokens ADD CONSTRAINT temp_unique_index UNIQUE(value_sha256);
ALTER TABLE executor_job_tokens DROP CONSTRAINT IF EXISTS executor_job_tokens_value_sha256_key;
ALTER TABLE executor_job_tokens RENAME CONSTRAINT temp_unique_index TO executor_job_tokens_value_sha256_key;
COMMIT AND CHAIN;

ALTER TABLE phabricator_repos ADD CONSTRAINT temp_unique_index UNIQUE(repo_name);
ALTER TABLE phabricator_repos DROP CONSTRAINT IF EXISTS phabricator_repos_repo_name_key;
ALTER TABLE phabricator_repos RENAME CONSTRAINT temp_unique_index TO phabricator_repos_repo_name_key;
COMMIT AND CHAIN;

ALTER TABLE repo ADD CONSTRAINT temp_unique_index UNIQUE(name) DEFERRABLE;;
ALTER TABLE repo DROP CONSTRAINT IF EXISTS repo_name_unique;
ALTER TABLE repo RENAME CONSTRAINT temp_unique_index TO repo_name_unique;
COMMIT AND CHAIN;

ALTER TABLE github_app_installs ADD CONSTRAINT temp_unique_index UNIQUE(app_id,installation_id);
ALTER TABLE github_app_installs DROP CONSTRAINT IF EXISTS unique_app_install;
ALTER TABLE github_app_installs RENAME CONSTRAINT temp_unique_index TO unique_app_install;
COMMIT AND CHAIN;

ALTER TABLE user_pending_permissions ADD CONSTRAINT temp_unique_index UNIQUE(service_type,service_id,permission,object_type,bind_id);
ALTER TABLE user_pending_permissions DROP CONSTRAINT IF EXISTS user_pending_permissions_service_perm_object_unique;
ALTER TABLE user_pending_permissions RENAME CONSTRAINT temp_unique_index TO user_pending_permissions_service_perm_object_unique;
COMMIT AND CHAIN;

ALTER TABLE code_hosts ADD CONSTRAINT temp_unique_index UNIQUE(url);
ALTER TABLE code_hosts DROP CONSTRAINT IF EXISTS code_hosts_url_key;
ALTER TABLE code_hosts RENAME CONSTRAINT temp_unique_index TO code_hosts_url_key;
COMMIT AND CHAIN;

ALTER TABLE commit_authors ADD CONSTRAINT temp_unique_index UNIQUE (email, name);
ALTER TABLE commit_authors DROP CONSTRAINT IF EXISTS commit_authors_email_name;
ALTER TABLE commit_authors RENAME CONSTRAINT temp_unique_index TO commit_authors_email_name;
COMMIT AND CHAIN;

ALTER TABLE package_repo_filters ADD CONSTRAINT temp_unique_index UNIQUE (scheme, matcher);
ALTER TABLE package_repo_filters DROP CONSTRAINT IF EXISTS package_repo_filters_unique_matcher_per_scheme;
ALTER TABLE package_repo_filters RENAME CONSTRAINT temp_unique_index TO package_repo_filters_unique_matcher_per_scheme;
COMMIT AND CHAIN;

CREATE UNIQUE INDEX IF NOT EXISTS access_tokens_tnt_id ON access_tokens (value_sha256, tenant_id);
COMMIT AND CHAIN;

CREATE UNIQUE INDEX IF NOT EXISTS repo_tnt_id ON repo USING btree (name, tenant_id);
