ALTER TABLE users ADD COLUMN IF NOT EXISTS unrestricted_repo_access boolean NOT NULL DEFAULT FALSE;
