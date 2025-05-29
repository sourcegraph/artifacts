DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'external_service_repos_repo_id_external_service_id_unique'
        AND conrelid = 'external_service_repos'::regclass
    ) THEN
        ALTER TABLE external_service_repos ADD CONSTRAINT external_service_repos_repo_id_external_service_id_unique UNIQUE (repo_id, external_service_id);
    END IF;
END;
$$;

COMMIT AND CHAIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sub_repo_permissions_repo_id_user_id_version_uindex'
        AND conrelid = 'sub_repo_permissions'::regclass
    ) THEN
        ALTER TABLE sub_repo_permissions ADD CONSTRAINT sub_repo_permissions_repo_id_user_id_version_uindex UNIQUE (repo_id, user_id, version);
    END IF;
END;
$$;
