-- Undo the changes made in the up migration
ALTER TABLE agent_conversations
    DROP COLUMN IF EXISTS external_creator_id,
    DROP COLUMN IF EXISTS external_creator_username;

ALTER TABLE agent_conversation_messages
    DROP COLUMN IF EXISTS external_creator_id,
    DROP COLUMN IF EXISTS external_creator_username;

ALTER TABLE agent_conversation_message_reactions
    DROP COLUMN IF EXISTS external_creator_id,
    DROP COLUMN IF EXISTS external_creator_username;

DROP INDEX IF EXISTS agent_conversations_external_creator_idx;
DROP INDEX IF EXISTS agent_conversation_messages_external_creator_idx;
DROP INDEX IF EXISTS agent_conversation_message_reactions_external_creator_idx;
