ALTER TABLE IF EXISTS external_service_sync_jobs
ADD COLUMN IF NOT EXISTS repos_wanted_to_delete INTEGER NOT NULL DEFAULT 0;
