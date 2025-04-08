-- Undo the changes made in the up migration

ALTER TABLE agent_rules DROP CONSTRAINT IF EXISTS agent_rules_state_enum;
ALTER TABLE agent_rules DROP COLUMN IF EXISTS state;
