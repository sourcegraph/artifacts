DO $$
BEGIN
    ALTER TABLE agent_conversations ADD CONSTRAINT agent_conversations_external_service_id_key UNIQUE (external_service_id, tenant_id);
EXCEPTION
    WHEN duplicate_table THEN NULL;
END $$;

DO $$
BEGIN
    ALTER TABLE agent_conversation_messages ADD CONSTRAINT agent_conversation_messages_external_service_id_key UNIQUE (external_service_id, tenant_id);
EXCEPTION
    WHEN duplicate_table THEN NULL;
END $$;
