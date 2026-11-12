-- The user a queued message turn runs as. NULL means the message author, or
-- the agent owner for automated wakes.
ALTER TABLE batch_change_agent_jobs ADD COLUMN IF NOT EXISTS actor_user_id integer;
