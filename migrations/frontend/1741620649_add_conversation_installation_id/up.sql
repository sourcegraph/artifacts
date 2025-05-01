-- This is intentionally not a foreign key on github_app_installs.install_id
-- because it's not a unique column.
ALTER TABLE agent_conversations ADD COLUMN IF NOT EXISTS installation_id bigint GENERATED ALWAYS AS ((data->>'installation_id')::bigint) STORED;
CREATE INDEX IF NOT EXISTS agent_conversations_installation_id_idx ON agent_conversations (installation_id);
