-- The Sourcegraph repository of a change request, used to enforce repository
-- permissions. NULL if the repository isn't on Sourcegraph when the change
-- request syncs. Change requests come from the code host, so deleting the
-- repository unlinks them rather than deleting them. The index keeps the
-- foreign key check fast when repositories are deleted.
ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS repo_id integer REFERENCES repo(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS change_requests_repo_id_idx ON change_requests (repo_id);

-- Adding the foreign key blocks writes to repo until the transaction ends, so
-- release it before the backfill.
COMMIT AND CHAIN;

-- GitHub change requests store the REST database ID of their repository.
-- Comparing it with the repository metadata as text, rather than with jsonb
-- containment, lets Postgres hash or merge join the tables in a single pass.
-- Without statistics for recently written change requests, Postgres can choose
-- a nested loop instead, which compares every change request with every
-- repository. SET LOCAL lasts until the migration's transaction ends.
SET LOCAL enable_nestloop = off;

UPDATE change_requests AS cr
SET repo_id = repo.id
FROM repo
WHERE cr.repo_id IS NULL
    AND cr.external_service_type = 'GITHUB'
    AND repo.tenant_id = cr.tenant_id
    AND repo.external_service_type = 'github'
    AND rtrim(repo.external_service_id, '/') = rtrim(cr.code_host_url, '/')
    AND repo.metadata->>'DatabaseID' = cr.external_repository_id
    AND repo.deleted_at IS NULL;
