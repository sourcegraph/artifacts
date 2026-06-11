ALTER TABLE batch_changes
    DROP CONSTRAINT IF EXISTS batch_changes_agent_id_fkey;
ALTER TABLE batch_changes
    ADD CONSTRAINT batch_changes_agent_id_fkey
    FOREIGN KEY (agent_id) REFERENCES batch_change_agents(id) ON DELETE SET NULL;

ALTER TABLE batch_change_agents
    DROP COLUMN IF EXISTS deleted_at;
