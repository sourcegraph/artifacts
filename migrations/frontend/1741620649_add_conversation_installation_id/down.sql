-- Undo the changes made in the up migration
ALTER TABLE agent_conversations DROP COLUMN IF EXISTS installation_id;
ALTER TABLE agent_conversations DROP CONSTRAINT IF EXISTS agent_conversations_agent_id_fkey;
ALTER TABLE agent_conversations ADD CONSTRAINT agent_conversations_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE;
