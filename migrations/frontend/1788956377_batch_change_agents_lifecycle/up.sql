ALTER TABLE batch_change_agents
    ADD COLUMN IF NOT EXISTS lifecycle_state TEXT NOT NULL DEFAULT 'in_progress';

ALTER TABLE batch_change_agents
    DROP CONSTRAINT IF EXISTS batch_change_agents_lifecycle_state_check;
ALTER TABLE batch_change_agents
    ADD CONSTRAINT batch_change_agents_lifecycle_state_check
    CHECK (lifecycle_state IN ('in_progress', 'archiving', 'completed', 'archived'));

COMMENT ON COLUMN batch_change_agents.lifecycle_state IS
    'Owner-directed lifecycle (in_progress, archiving, completed, archived). Distinct from derived activity status.';

ALTER TABLE batch_change_agent_thread_entries
    DROP CONSTRAINT IF EXISTS batch_change_agent_thread_entries_kind_check;
ALTER TABLE batch_change_agent_thread_entries
    ADD CONSTRAINT batch_change_agent_thread_entries_kind_check CHECK (
        kind IN ('user_message', 'thinking', 'assistant_text', 'tool_call', 'tool_result', 'compaction', 'error', 'lifecycle')
    );
