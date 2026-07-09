ALTER TABLE batch_change_agent_messages DROP COLUMN IF EXISTS wake_kind;
DROP TABLE IF EXISTS batch_change_agent_wake_jobs;
DROP TABLE IF EXISTS batch_change_agent_inbox_cursors;
DROP TABLE IF EXISTS batch_change_agent_inbox_items;
