-- Undo the changes made in the up migration
--- Remove message_id, reaction_id, changeset_id from agent_review_diagnostic_feedback
ALTER TABLE agent_review_diagnostic_feedback
    DROP COLUMN IF EXISTS message_id,
    DROP COLUMN IF EXISTS reaction_id,
    DROP COLUMN IF EXISTS changeset_id;

--- Remove conversation_id from agent_conversation_conversation_message_reactions
ALTER TABLE agent_conversation_message_reactions
    DROP COLUMN IF EXISTS conversation_id;
