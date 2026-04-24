ALTER TABLE abc_executor_tasks ADD COLUMN IF NOT EXISTS executor_secrets TEXT[] NOT NULL DEFAULT '{}';
