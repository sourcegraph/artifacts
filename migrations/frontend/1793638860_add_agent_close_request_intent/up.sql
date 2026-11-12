ALTER TABLE batch_change_agents
    ADD COLUMN IF NOT EXISTS close_requested_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN batch_change_agents.close_requested_at IS
    'First request to close the stopped agent''s open changesets; retained for cleanup retries.';
