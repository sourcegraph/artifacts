ALTER TABLE batch_change_agent_turns
    DROP COLUMN IF EXISTS thinking,
    DROP COLUMN IF EXISTS thinking_signature;
