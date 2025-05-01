-- configuration_policies_audit_logs
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'configuration_policies_audit_logs_pkey'
        AND conrelid = 'configuration_policies_audit_logs'::regclass
    ) THEN
        ALTER TABLE configuration_policies_audit_logs DROP CONSTRAINT configuration_policies_audit_logs_pkey;
        ALTER TABLE configuration_policies_audit_logs DROP COLUMN id;
    END IF;
END;
$$;

-- external_service_repos
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'external_service_repos_pkey'
        AND conrelid = 'external_service_repos'::regclass
    ) THEN
        ALTER TABLE external_service_repos DROP CONSTRAINT external_service_repos_pkey;
    END IF;
END;
$$;

-- feature_flag_overrides
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'feature_flag_overrides_pkey'
        AND conrelid = 'feature_flag_overrides'::regclass
    ) THEN
        ALTER TABLE feature_flag_overrides DROP CONSTRAINT feature_flag_overrides_pkey;
        ALTER TABLE feature_flag_overrides DROP COLUMN id;
    END IF;
END;
$$;

-- lsif_nearest_uploads
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_nearest_uploads_pkey'
        AND conrelid = 'lsif_nearest_uploads'::regclass
    ) THEN
        ALTER TABLE lsif_nearest_uploads DROP CONSTRAINT lsif_nearest_uploads_pkey;
        ALTER TABLE lsif_nearest_uploads DROP COLUMN id;
    END IF;
END;
$$;

-- lsif_nearest_uploads_links
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_nearest_uploads_links_pkey'
        AND conrelid = 'lsif_nearest_uploads_links'::regclass
    ) THEN
        ALTER TABLE lsif_nearest_uploads_links DROP CONSTRAINT lsif_nearest_uploads_links_pkey;
        ALTER TABLE lsif_nearest_uploads_links DROP COLUMN id;
    END IF;
END;
$$;

-- lsif_uploads_audit_logs
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_uploads_audit_logs_pkey'
        AND conrelid = 'lsif_uploads_audit_logs'::regclass
    ) THEN
        ALTER TABLE lsif_uploads_audit_logs DROP CONSTRAINT lsif_uploads_audit_logs_pkey;
    END IF;
END;
$$;

-- lsif_uploads_reference_counts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_uploads_reference_counts_upload_id_key'
        AND conrelid = 'lsif_uploads_reference_counts'::regclass
    ) THEN
        ALTER TABLE lsif_uploads_reference_counts ADD CONSTRAINT lsif_uploads_reference_counts_upload_id_key UNIQUE (upload_id);
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_uploads_reference_counts_pkey'
        AND conrelid = 'lsif_uploads_reference_counts'::regclass
    ) THEN
        ALTER TABLE lsif_uploads_reference_counts DROP CONSTRAINT lsif_uploads_reference_counts_pkey;
    END IF;
END;
$$;

-- lsif_uploads_visible_at_tip
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_uploads_visible_at_tip_pkey'
        AND conrelid = 'lsif_uploads_visible_at_tip'::regclass
    ) THEN
        ALTER TABLE lsif_uploads_visible_at_tip DROP CONSTRAINT lsif_uploads_visible_at_tip_pkey;
        ALTER TABLE lsif_uploads_visible_at_tip DROP COLUMN id;
    END IF;
END;
$$;

-- repo_pending_permissions
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'repo_pending_permissions_pkey'
        AND conrelid = 'repo_pending_permissions'::regclass
    ) THEN
        ALTER TABLE repo_pending_permissions DROP CONSTRAINT repo_pending_permissions_pkey;
        ALTER TABLE repo_pending_permissions DROP COLUMN id;
    END IF;
END;
$$;

-- repo_permissions
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'repo_permissions_pkey'
        AND conrelid = 'repo_permissions'::regclass
    ) THEN
        ALTER TABLE repo_permissions DROP CONSTRAINT repo_permissions_pkey;
        ALTER TABLE repo_permissions DROP COLUMN id;
    END IF;
END;
$$;

-- repo_statistics
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'repo_statistics_pkey'
        AND conrelid = 'repo_statistics'::regclass
    ) THEN
        ALTER TABLE repo_statistics DROP CONSTRAINT repo_statistics_pkey;
        ALTER TABLE repo_statistics DROP COLUMN id;
    END IF;
END;
$$;

-- search_context_repos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'search_context_repos_unique'
        AND conrelid = 'search_context_repos'::regclass
    ) THEN
        ALTER TABLE search_context_repos ADD CONSTRAINT search_context_repos_unique UNIQUE (repo_id, search_context_id, revision);
    END IF;
END;
$$;
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'search_context_repos_pkey'
        AND conrelid = 'search_context_repos'::regclass
    ) THEN
        ALTER TABLE search_context_repos DROP CONSTRAINT search_context_repos_pkey;
    END IF;
END;
$$;

-- sub_repo_permissions
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sub_repo_permissions_pkey'
        AND conrelid = 'sub_repo_permissions'::regclass
    ) THEN
        ALTER TABLE sub_repo_permissions DROP CONSTRAINT sub_repo_permissions_pkey;
    END IF;
END;
$$;

-- user_emails
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'user_emails_pkey'
        AND conrelid = 'user_emails'::regclass
    ) THEN
        ALTER TABLE user_emails DROP CONSTRAINT user_emails_pkey;
        ALTER TABLE user_emails DROP COLUMN id;
    END IF;
END;
$$;

-- user_pending_permissions
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'user_pending_permissions_pkey'
        AND conrelid = 'user_pending_permissions'::regclass
    ) THEN
        ALTER TABLE user_pending_permissions DROP CONSTRAINT user_pending_permissions_pkey;
    END IF;
END;
$$;

-- user_permissions
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'user_permissions_pkey'
        AND conrelid = 'user_permissions'::regclass
    ) THEN
        ALTER TABLE user_permissions DROP CONSTRAINT user_permissions_pkey;
        ALTER TABLE user_permissions DROP COLUMN id;
    END IF;
END;
$$;

-- codeintel_inference_scripts
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'codeintel_inference_scripts_pkey'
        AND conrelid = 'codeintel_inference_scripts'::regclass
    ) THEN
        ALTER TABLE codeintel_inference_scripts DROP CONSTRAINT codeintel_inference_scripts_pkey;
        ALTER TABLE codeintel_inference_scripts DROP COLUMN id;
    END IF;
END;
$$;

-- codeintel_langugage_support_requests
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'codeintel_langugage_support_requests_pkey'
        AND conrelid = 'codeintel_langugage_support_requests'::regclass
    ) THEN
        ALTER TABLE codeintel_langugage_support_requests DROP CONSTRAINT codeintel_langugage_support_requests_pkey;
    END IF;
END;
$$;

-- insights_settings_migration_jobs
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'insights_settings_migration_jobs_pkey'
        AND conrelid = 'insights_settings_migration_jobs'::regclass
    ) THEN
        ALTER TABLE insights_settings_migration_jobs DROP CONSTRAINT insights_settings_migration_jobs_pkey;
    END IF;
END;
$$;
