-- The owner's choice of who can find the agent, bounded by the
-- experimentalFeatures.batchChanges.agenticBatchChanges.sharing site setting.
-- NULL follows that setting. Valid values are application-defined
-- ('link-only', 'global'); see internal/batchchangeagents.AgentVisibility.
ALTER TABLE batch_change_agents ADD COLUMN IF NOT EXISTS visibility TEXT;

COMMENT ON COLUMN batch_change_agents.visibility IS
    'Owner-chosen visibility (link-only or global), clamped by the instance sharing setting. NULL follows the instance setting.';
