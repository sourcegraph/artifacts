ALTER TABLE repo_update_jobs ADD COLUMN IF NOT EXISTS is_reclone boolean NOT NULL DEFAULT false;
