-- Whether the change request's repository is archived, or otherwise read-only,
-- on the code host. Code hosts without such a concept always store false.
ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS repository_archived BOOLEAN NOT NULL DEFAULT FALSE;
