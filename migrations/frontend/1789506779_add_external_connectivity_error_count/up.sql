ALTER TABLE gitserver_repos
ADD COLUMN IF NOT EXISTS consecutive_external_connectivity_errors INTEGER NOT NULL DEFAULT 0;
