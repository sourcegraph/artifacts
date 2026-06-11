DROP TABLE IF EXISTS batch_change_agent_spec_drafts;
ALTER TABLE batch_changes DROP COLUMN IF EXISTS agent_id;
DROP INDEX IF EXISTS batch_changes_one_active_agent_idx;
DROP TABLE IF EXISTS batch_change_agent_jobs;
DROP TABLE IF EXISTS batch_change_agent_turns;
DROP TABLE IF EXISTS batch_change_agent_messages;
DROP TABLE IF EXISTS batch_change_agent_threads;
DROP TABLE IF EXISTS batch_change_agents;
