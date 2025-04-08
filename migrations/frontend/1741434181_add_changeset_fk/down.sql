-- Undo the changes made in the up migration

ALTER TABLE agent_reviews DROP COLUMN IF EXISTS changeset_id;
ALTER TABLE agent_reviews DROP COLUMN IF EXISTS changeset_revision_id;

ALTER TABLE agent_conversations DROP COLUMN IF EXISTS changeset_id;
ALTER TABLE agent_conversations DROP COLUMN IF EXISTS changeset_revision_id;
ALTER TABLE agent_conversations DROP COLUMN IF EXISTS repo_id;
