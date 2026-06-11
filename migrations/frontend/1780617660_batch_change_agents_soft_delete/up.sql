-- Soft-delete support for batch change agents. Deleting an agent now sets
-- deleted_at instead of removing the row, so the batch_changes.agent_id
-- relation (and the agent's threads/spec drafts) are retained and the batch
-- change continues to be treated as agent-managed.
ALTER TABLE batch_change_agents
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Soft-deletion is how an agent is "closed" while keeping its batch change.
-- A hard delete of the agent row is therefore a real, intentional removal:
-- cascade it to the associated batch change instead of just nulling the link.
ALTER TABLE batch_changes
    DROP CONSTRAINT IF EXISTS batch_changes_agent_id_fkey;
ALTER TABLE batch_changes
    ADD CONSTRAINT batch_changes_agent_id_fkey
    FOREIGN KEY (agent_id) REFERENCES batch_change_agents(id) ON DELETE CASCADE;
