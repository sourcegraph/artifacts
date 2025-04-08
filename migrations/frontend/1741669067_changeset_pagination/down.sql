-- Undo the changes made in the up migration

ALTER TABLE agent_changesets DROP COLUMN IF EXISTS external_created_at;
ALTER TABLE agent_changesets DROP COLUMN IF EXISTS external_updated_at;
ALTER TABLE agent_changesets DROP COLUMN IF EXISTS is_open;
ALTER TABLE agent_changesets DROP COLUMN IF EXISTS is_merged;
ALTER TABLE agent_changesets DROP COLUMN IF EXISTS mergeable_state;
ALTER TABLE agent_changesets DROP COLUMN IF EXISTS author_external_username;
ALTER TABLE agent_changesets DROP COLUMN IF EXISTS state;
ALTER TABLE agent_changesets DROP COLUMN IF EXISTS draft;
