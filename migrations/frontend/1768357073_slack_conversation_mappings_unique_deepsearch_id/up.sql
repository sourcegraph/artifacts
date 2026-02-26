ALTER TABLE slack_conversation_mappings
    DROP CONSTRAINT IF EXISTS slack_conversation_mappings_unique_deepsearch_id;

ALTER TABLE slack_conversation_mappings
    ADD CONSTRAINT slack_conversation_mappings_unique_deepsearch_id
    UNIQUE (tenant_id, deepsearch_conversation_id);
