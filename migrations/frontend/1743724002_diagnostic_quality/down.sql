-- Undo the changes made in the up migration
ALTER TABLE agent_review_diagnostics DROP COLUMN IF EXISTS quality;
