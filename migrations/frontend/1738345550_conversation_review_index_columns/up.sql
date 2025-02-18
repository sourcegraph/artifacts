ALTER TABLE agent_reviews
    ADD COLUMN IF NOT EXISTS pull_request_api_url TEXT GENERATED ALWAYS AS (data->'request'->'diff'->>'pull_request_api_url') STORED;

ALTER TABLE agent_conversations
    ADD COLUMN IF NOT EXISTS external_service_id TEXT GENERATED ALWAYS AS (data->>'external_service_id') STORED,
    ADD COLUMN IF NOT EXISTS external_created_at TEXT GENERATED ALWAYS AS (data->>'external_created_at') STORED,
    ADD COLUMN IF NOT EXISTS external_updated_at TEXT GENERATED ALWAYS AS (data->>'external_updated_at') STORED;

ALTER TABLE agent_conversation_messages
    ADD COLUMN IF NOT EXISTS external_service_id TEXT GENERATED ALWAYS AS (data->>'external_service_id') STORED,
    ADD COLUMN IF NOT EXISTS external_created_at TEXT GENERATED ALWAYS AS (data->>'external_created_at') STORED,
    ADD COLUMN IF NOT EXISTS external_updated_at TEXT GENERATED ALWAYS AS (data->>'external_updated_at') STORED;

CREATE INDEX IF NOT EXISTS agent_conversations_external_service_idx ON agent_conversations(external_service_id);
CREATE INDEX IF NOT EXISTS agent_conversation_messages_external_service_idx ON agent_conversation_messages(external_service_id);
CREATE INDEX IF NOT EXISTS agent_reviews_pull_request_api_url ON agent_reviews(pull_request_api_url);

ALTER TABLE agent_conversations
    ADD COLUMN pull_request_id_generated BIGINT GENERATED ALWAYS AS ((data->>'pull_request_id')::BIGINT) STORED;

ALTER TABLE agent_conversations
    DROP COLUMN pull_request_id;

ALTER TABLE agent_conversations
    RENAME COLUMN pull_request_id_generated TO pull_request_id;
