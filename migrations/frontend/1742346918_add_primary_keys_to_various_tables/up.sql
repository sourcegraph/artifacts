-- configuration_policies_audit_logs
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'configuration_policies_audit_logs_pkey'
        AND conrelid = 'configuration_policies_audit_logs'::regclass
    ) THEN
        ALTER TABLE configuration_policies_audit_logs ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- external_service_repos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'external_service_repos_pkey'
        AND conrelid = 'external_service_repos'::regclass
    ) THEN
        ALTER TABLE external_service_repos ADD PRIMARY KEY (repo_id, external_service_id);
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- feature_flag_overrides
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'feature_flag_overrides_pkey'
        AND conrelid = 'feature_flag_overrides'::regclass
    ) THEN
        ALTER TABLE feature_flag_overrides ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- lsif_nearest_uploads
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_nearest_uploads_pkey'
        AND conrelid = 'lsif_nearest_uploads'::regclass
    ) THEN
        ALTER TABLE lsif_nearest_uploads ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- lsif_nearest_uploads_links
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_nearest_uploads_links_pkey'
        AND conrelid = 'lsif_nearest_uploads_links'::regclass
    ) THEN
        ALTER TABLE lsif_nearest_uploads_links ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- lsif_uploads_audit_logs
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_uploads_audit_logs_pkey'
        AND conrelid = 'lsif_uploads_audit_logs'::regclass
    ) THEN
        -- Use the existing sequence column as primary key
        ALTER TABLE lsif_uploads_audit_logs ADD PRIMARY KEY (sequence);
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- lsif_uploads_reference_counts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_uploads_reference_counts_pkey'
        AND conrelid = 'lsif_uploads_reference_counts'::regclass
    ) THEN
        ALTER TABLE lsif_uploads_reference_counts ADD PRIMARY KEY (upload_id);
    END IF;
END;
$$;

ALTER TABLE lsif_uploads_reference_counts DROP CONSTRAINT IF EXISTS lsif_uploads_reference_counts_upload_id_key;

COMMIT AND CHAIN;

-- lsif_uploads_visible_at_tip
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'lsif_uploads_visible_at_tip_pkey'
        AND conrelid = 'lsif_uploads_visible_at_tip'::regclass
    ) THEN
        ALTER TABLE lsif_uploads_visible_at_tip ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- repo_pending_permissions
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'repo_pending_permissions_pkey'
        AND conrelid = 'repo_pending_permissions'::regclass
    ) THEN
        -- We can use the existing unique constraint
        ALTER TABLE repo_pending_permissions ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- repo_permissions
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'repo_permissions_pkey'
        AND conrelid = 'repo_permissions'::regclass
    ) THEN
        -- We can use the existing unique constraint
        ALTER TABLE repo_permissions ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- repo_statistics
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'repo_statistics_pkey'
        AND conrelid = 'repo_statistics'::regclass
    ) THEN
        ALTER TABLE repo_statistics ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- search_context_repos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'search_context_repos_pkey'
        AND conrelid = 'search_context_repos'::regclass
    ) THEN
        -- Use existing unique constraint
        ALTER TABLE search_context_repos ADD PRIMARY KEY (repo_id, search_context_id, revision);
    END IF;
END;
$$;

ALTER TABLE search_context_repos DROP CONSTRAINT IF EXISTS search_context_repos_unique;

COMMIT AND CHAIN;

-- sub_repo_permissions
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sub_repo_permissions_pkey'
        AND conrelid = 'sub_repo_permissions'::regclass
    ) THEN
        ALTER TABLE sub_repo_permissions ADD PRIMARY KEY (repo_id, user_id, version);
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- user_emails
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'user_emails_pkey'
        AND conrelid = 'user_emails'::regclass
    ) THEN
        ALTER TABLE user_emails ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- user_pending_permissions
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'user_pending_permissions_pkey'
        AND conrelid = 'user_pending_permissions'::regclass
    ) THEN
        -- Can use the service unique constraint
        ALTER TABLE user_pending_permissions ADD PRIMARY KEY (id);
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- user_permissions
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'user_permissions_pkey'
        AND conrelid = 'user_permissions'::regclass
    ) THEN
        -- Can use unique constraint
        ALTER TABLE user_permissions ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- codeintel_inference_scripts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'codeintel_inference_scripts_pkey'
        AND conrelid = 'codeintel_inference_scripts'::regclass
    ) THEN
        ALTER TABLE codeintel_inference_scripts ADD COLUMN IF NOT EXISTS id BIGSERIAL PRIMARY KEY;
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- codeintel_langugage_support_requests
DO $$
BEGIN
    -- This table already has an id, just make it a primary key if it's not already
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'codeintel_langugage_support_requests_pkey'
        AND conrelid = 'codeintel_langugage_support_requests'::regclass
    ) THEN
        ALTER TABLE codeintel_langugage_support_requests ADD PRIMARY KEY (id);
    END IF;
END;
$$;

COMMIT AND CHAIN;

-- insights_settings_migration_jobs
DO $$
BEGIN
    -- This table already has an id, just make it a primary key if it's not already
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'insights_settings_migration_jobs_pkey'
        AND conrelid = 'insights_settings_migration_jobs'::regclass
    ) THEN
        ALTER TABLE insights_settings_migration_jobs ADD PRIMARY KEY (id);
    END IF;
END;
$$;
