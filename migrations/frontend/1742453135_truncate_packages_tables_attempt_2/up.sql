-- Keep these tables around to avoid back-compat tests from complaining.
-- We can remove these tables in a future migration.

TRUNCATE TABLE package_repo_filters;
TRUNCATE TABLE package_repo_versions;

WITH package_repo_ids AS (
    SELECT esr.repo_id
    FROM external_service_repos esr
     JOIN external_services es ON es.id = esr.external_service_id
     JOIN code_hosts ch ON es.code_host_id = ch.id
    WHERE ch.kind IN ('GOMODULES', 'JVMPACKAGES', 'NPMPACKAGES', 'PYTHONPACKAGES', 'RUBYPACKAGES', 'RUSTPACKAGES')
)
UPDATE repo
    SET
        name = soft_deleted_repository_name(name),
        deleted_at = NOW()
WHERE deleted_at IS NULL AND id IN (SELECT repo_id FROM package_repo_ids);
-- Soft-delete instead of hard-deleting to allow cleanup routines to
-- do their work.

WITH code_host_ids AS (
    SELECT id
    FROM code_hosts
    WHERE kind IN ('GOMODULES', 'JVMPACKAGES', 'NPMPACKAGES', 'PYTHONPACKAGES', 'RUBYPACKAGES', 'RUSTPACKAGES')
)
DELETE FROM external_services
WHERE code_host_id IN (SELECT id FROM code_host_ids);

DELETE FROM code_hosts
WHERE kind IN ('GOMODULES', 'JVMPACKAGES', 'NPMPACKAGES', 'PYTHONPACKAGES', 'RUBYPACKAGES', 'RUSTPACKAGES');
