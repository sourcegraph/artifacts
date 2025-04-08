-- Undo the changes made in the up migration
DROP TABLE IF EXISTS agent_changesets CASCADE;
DROP FUNCTION IF EXISTS update_agent_changesets_updated_at();
DROP TRIGGER IF EXISTS update_agent_changesets_updated_at ON agent_changesets;
DROP TABLE IF EXISTS agent_changeset_revisions CASCADE;
