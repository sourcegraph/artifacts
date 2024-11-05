-- Big on dotcom, but probably nowhere else.
--                       table_name                       |    size    | tuple_count
-- -------------------------------------------------------+------------+-------------
--  access_tokens                                         | 2461 MB    |     1230695
DO
$$
BEGIN
    IF to_regclass('access_tokens_tnt_id') IS NOT NULL THEN
        ALTER TABLE access_tokens DROP CONSTRAINT IF EXISTS access_tokens_value_sha256_key;
        ALTER TABLE access_tokens ADD CONSTRAINT access_tokens_value_sha256_key UNIQUE USING INDEX access_tokens_tnt_id;
   END IF;
END
$$;
COMMIT AND CHAIN;

-- Should be small enough.
ALTER TABLE executor_heartbeats ADD CONSTRAINT temp_unique_index UNIQUE(hostname,tenant_id);
ALTER TABLE executor_heartbeats DROP CONSTRAINT IF EXISTS executor_heartbeats_hostname_key;
ALTER TABLE executor_heartbeats RENAME CONSTRAINT temp_unique_index TO executor_heartbeats_hostname_key;
COMMIT AND CHAIN;

-- Should be small enough.
ALTER TABLE executor_job_tokens ADD CONSTRAINT temp_unique_index UNIQUE(value_sha256,tenant_id);
ALTER TABLE executor_job_tokens DROP CONSTRAINT IF EXISTS executor_job_tokens_value_sha256_key;
ALTER TABLE executor_job_tokens RENAME CONSTRAINT temp_unique_index TO executor_job_tokens_value_sha256_key;
COMMIT AND CHAIN;

-- Should be small enough.
ALTER TABLE phabricator_repos ADD CONSTRAINT temp_unique_index UNIQUE(repo_name,tenant_id);
ALTER TABLE phabricator_repos DROP CONSTRAINT IF EXISTS phabricator_repos_repo_name_key;
ALTER TABLE phabricator_repos RENAME CONSTRAINT temp_unique_index TO phabricator_repos_repo_name_key;
COMMIT AND CHAIN;

-- Big on dotcom, but probably nowhere else.
--                       table_name                       |    size    | tuple_count
-- -------------------------------------------------------+------------+-------------
--  repo                                                  | 43 GB      |     3442994
DO
$$
BEGIN
    IF to_regclass('repo_tnt_id') IS NOT NULL THEN
        ALTER TABLE repo DROP CONSTRAINT IF EXISTS repo_name_unique;
        ALTER TABLE repo ADD CONSTRAINT repo_name_unique UNIQUE USING INDEX repo_tnt_id DEFERRABLE;
   END IF;
END
$$;
COMMIT AND CHAIN;

-- Should be small enough.
ALTER TABLE github_app_installs ADD CONSTRAINT temp_unique_index UNIQUE(app_id,installation_id,tenant_id);
ALTER TABLE github_app_installs DROP CONSTRAINT IF EXISTS unique_app_install;
ALTER TABLE github_app_installs RENAME CONSTRAINT temp_unique_index TO unique_app_install;
COMMIT AND CHAIN;

-- Should be small enough.
ALTER TABLE user_pending_permissions ADD CONSTRAINT temp_unique_index UNIQUE(service_type,service_id,permission,object_type,bind_id,tenant_id);
ALTER TABLE user_pending_permissions DROP CONSTRAINT IF EXISTS user_pending_permissions_service_perm_object_unique;
ALTER TABLE user_pending_permissions RENAME CONSTRAINT temp_unique_index TO user_pending_permissions_service_perm_object_unique;
COMMIT AND CHAIN;

-- Should be small enough.
ALTER TABLE code_hosts ADD CONSTRAINT temp_unique_index UNIQUE(url,tenant_id);
ALTER TABLE code_hosts DROP CONSTRAINT IF EXISTS code_hosts_url_key;
ALTER TABLE code_hosts RENAME CONSTRAINT temp_unique_index TO code_hosts_url_key;
COMMIT AND CHAIN;

-- Should be small enough.
ALTER TABLE commit_authors ADD CONSTRAINT temp_unique_index UNIQUE (email, name, tenant_id);
ALTER TABLE commit_authors DROP CONSTRAINT IF EXISTS commit_authors_email_name;
ALTER TABLE commit_authors RENAME CONSTRAINT temp_unique_index TO commit_authors_email_name;
COMMIT AND CHAIN;

-- Should be small enough.
ALTER TABLE package_repo_filters ADD CONSTRAINT temp_unique_index UNIQUE (scheme, matcher, tenant_id);
ALTER TABLE package_repo_filters DROP CONSTRAINT IF EXISTS package_repo_filters_unique_matcher_per_scheme;
ALTER TABLE package_repo_filters RENAME CONSTRAINT temp_unique_index TO package_repo_filters_unique_matcher_per_scheme;
