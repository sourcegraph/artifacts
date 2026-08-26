ALTER TABLE batch_change_agent_turns
    ADD COLUMN IF NOT EXISTS thinking TEXT,
    ADD COLUMN IF NOT EXISTS thinking_signature TEXT;
