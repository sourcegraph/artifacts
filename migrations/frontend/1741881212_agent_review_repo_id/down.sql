-- Undo the changes made in the up migration

ALTER TABLE agent_reviews DROP COLUMN IF EXISTS repo_id;
