-- Drop the non-unique index
DROP INDEX IF EXISTS slack_conversation_mappings_channel_thread_idx;

-- Delete duplicate rows, keeping only the most recent per (tenant_id, channel, thread)
DELETE FROM slack_conversation_mappings a
USING slack_conversation_mappings b
WHERE a.tenant_id = b.tenant_id
  AND a.slack_channel = b.slack_channel
  AND a.slack_thread_ts = b.slack_thread_ts
  AND a.created_at < b.created_at;

-- Restore the unique constraint
ALTER TABLE slack_conversation_mappings
    DROP CONSTRAINT IF EXISTS slack_conversation_mappings_channel_thread_key;
ALTER TABLE slack_conversation_mappings
    ADD CONSTRAINT slack_conversation_mappings_channel_thread_key
    UNIQUE (tenant_id, slack_channel, slack_thread_ts);
