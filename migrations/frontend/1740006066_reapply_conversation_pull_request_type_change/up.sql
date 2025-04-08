-- Some goofball (AKA me) edited a migration that had already been applied in a number of environments
-- the migration in question was https://github.com/sourcegraph/sourcegraph/blob/3ed51e4ae6ccfe5e239bf952ccf2ed9e1bc328d9/migrations/frontend/1738345550_conversation_review_index_columns
-- this migration should only apply to instances which applied the v1 of the migration and apply the same set of changes
-- as in the v2 of the migration
-- let this be a lesson to you to not edit merged migrations!
DO $$
BEGIN
    IF EXISTS(
        SELECT
            1
        FROM
            information_schema.columns
        WHERE
            table_name = 'agent_conversations'
            AND column_name = 'external_service_id'
            AND data_type = 'bigint') THEN
    ALTER TABLE agent_conversations
        DROP COLUMN IF EXISTS external_service_id,
        ADD COLUMN external_service_id TEXT GENERATED ALWAYS AS(data ->> 'external_service_id') STORED;
    CREATE INDEX IF NOT EXISTS agent_conversations_external_service_idx ON agent_conversations(external_service_id);
    ALTER TABLE agent_conversation_messages
        DROP COLUMN IF EXISTS external_service_id,
        ADD COLUMN external_service_id TEXT GENERATED ALWAYS AS(data ->> 'external_service_id') STORED;
    -- Add new timestamp columns that don't exist in old version
    ALTER TABLE agent_conversations
        ADD COLUMN IF NOT EXISTS external_created_at TEXT GENERATED ALWAYS AS(data ->> 'external_created_at') STORED,
        ADD COLUMN IF NOT EXISTS external_updated_at TEXT GENERATED ALWAYS AS(data ->> 'external_updated_at') STORED;
    ALTER TABLE agent_conversation_messages
        ADD COLUMN IF NOT EXISTS external_created_at TEXT GENERATED ALWAYS AS(data ->> 'external_created_at') STORED,
        ADD COLUMN IF NOT EXISTS external_updated_at TEXT GENERATED ALWAYS AS(data ->> 'external_updated_at') STORED;
    -- Handle pull_request_id column transformation
    ALTER TABLE agent_conversations
        DROP COLUMN IF EXISTS pull_request_id,
        ADD COLUMN IF NOT EXISTS pull_request_id BIGINT GENERATED ALWAYS AS((data ->> 'pull_request_id')::bigint) STORED;
    -- Ensure the agent_reviews index has the correct name
    DROP INDEX IF EXISTS agent_reviews_pull_request_api_url;
    CREATE INDEX IF NOT EXISTS agent_reviews_pull_request_api_url ON agent_reviews(pull_request_api_url);
    ALTER TABLE agent_conversation_messages
        ADD CONSTRAINT agent_conversation_messages_external_service_id_key UNIQUE(external_service_id, tenant_id);
END IF;
END
$$;
