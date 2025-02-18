ALTER TABLE agent_reviews
    DROP COLUMN IF EXISTS pull_request_api_url CASCADE;

ALTER TABLE agent_conversations
    DROP COLUMN IF EXISTS external_service_id,
    DROP COLUMN IF EXISTS external_created_at,
    DROP COLUMN IF EXISTS external_updated_at;

ALTER TABLE agent_conversation_messages
    DROP COLUMN IF EXISTS external_service_id,
    DROP COLUMN IF EXISTS external_created_at,
    DROP COLUMN IF EXISTS external_updated_at;

ALTER TABLE agent_conversations ALTER COLUMN pull_request_id TYPE INT;

ALTER TABLE agent_conversations
    ADD COLUMN small_pull_request_id INT GENERATED ALWAYS AS ((data->>'pull_request_id')::INT) STORED;

ALTER TABLE agent_conversations
    DROP COLUMN pull_request_id;

ALTER TABLE agent_conversations
    RENAME COLUMN small_pull_request_id TO pull_request_id;

CREATE INDEX IF NOT EXISTS agent_conversations_pull_request_id_idx ON agent_conversations(pull_request_id);
