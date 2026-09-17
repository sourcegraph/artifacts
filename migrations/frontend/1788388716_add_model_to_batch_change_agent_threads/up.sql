ALTER TABLE batch_change_agent_threads
    ADD COLUMN IF NOT EXISTS model TEXT;

COMMENT ON COLUMN batch_change_agent_threads.model IS
    'Internal model override used for all LLM requests in this agent thread.';
