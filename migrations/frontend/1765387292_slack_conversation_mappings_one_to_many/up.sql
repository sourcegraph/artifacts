-- Drop the unique constraint to allow multiple conversations per slack thread
ALTER TABLE slack_conversation_mappings DROP CONSTRAINT IF EXISTS slack_conversation_mappings_channel_thread_key;

-- Add an index for efficient lookups (non-unique, ordered by created_at desc for getting latest)
CREATE INDEX IF NOT EXISTS slack_conversation_mappings_channel_thread_idx
    ON slack_conversation_mappings (tenant_id, slack_channel, slack_thread_ts, created_at DESC);
