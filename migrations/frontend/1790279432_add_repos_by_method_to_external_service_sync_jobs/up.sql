ALTER TABLE external_service_sync_jobs
    ADD COLUMN IF NOT EXISTS repos_by_method jsonb NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN external_service_sync_jobs.repos_by_method IS 'Per-method repository counters: a list of {option, value, errors, added, modified, unmodified} objects, one per code host connection config option (e.g. "orgs") and value (e.g. the org name) that listed repositories.';
