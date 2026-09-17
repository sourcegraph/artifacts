ALTER TABLE batch_change_agent_thread_entries
    DROP CONSTRAINT IF EXISTS batch_change_agent_thread_entries_kind_check;
ALTER TABLE batch_change_agent_thread_entries
    ADD CONSTRAINT batch_change_agent_thread_entries_kind_check CHECK (
        kind IN ('user_message', 'thinking', 'assistant_text', 'tool_call', 'tool_result', 'compaction', 'error')
    );

ALTER TABLE batch_change_agents
    DROP CONSTRAINT IF EXISTS batch_change_agents_lifecycle_state_check;
ALTER TABLE batch_change_agents
    DROP COLUMN IF EXISTS lifecycle_state;
