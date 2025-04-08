ALTER TABLE agent_conversations
    ADD COLUMN IF NOT EXISTS external_creator_id TEXT GENERATED ALWAYS AS (data->>'external_creator_id') STORED,
    ADD COLUMN IF NOT EXISTS external_creator_username TEXT GENERATED ALWAYS AS (data->>'external_creator_username') STORED;

ALTER TABLE agent_conversation_messages
    ADD COLUMN IF NOT EXISTS external_creator_id TEXT GENERATED ALWAYS AS (data->>'external_creator_id') STORED,
    ADD COLUMN IF NOT EXISTS external_creator_username TEXT GENERATED ALWAYS AS (data->>'external_creator_username') STORED;

ALTER TABLE agent_conversation_message_reactions
    ADD COLUMN IF NOT EXISTS external_creator_id TEXT GENERATED ALWAYS AS (data->>'external_creator_id') STORED,
    ADD COLUMN IF NOT EXISTS external_creator_username TEXT GENERATED ALWAYS AS (data->>'external_creator_username') STORED;

CREATE INDEX IF NOT EXISTS agent_conversations_external_creator_idx ON agent_conversations(external_creator_id);
CREATE INDEX IF NOT EXISTS agent_conversation_messages_external_creator_idx ON agent_conversation_messages(external_creator_id);
CREATE INDEX IF NOT EXISTS agent_conversation_message_reactions_external_creator_idx ON agent_conversation_message_reactions(external_creator_id);
