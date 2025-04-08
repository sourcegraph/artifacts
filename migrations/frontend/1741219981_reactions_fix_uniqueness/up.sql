DROP INDEX IF EXISTS agent_conversation_message_reactions_external_service_id_idx;

CREATE UNIQUE INDEX IF NOT EXISTS agent_conversation_message_reactions_external_service_id_idx ON agent_conversation_message_reactions (tenant_id, external_service_id);

DO $$
BEGIN
    ALTER TABLE agent_conversation_message_reactions
    ADD CONSTRAINT agent_conversation_message_reactions_external_service_id_key
    UNIQUE USING INDEX agent_conversation_message_reactions_external_service_id_idx;
EXCEPTION
    WHEN duplicate_table THEN NULL;
END $$;
