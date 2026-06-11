ALTER TABLE executor_heartbeats ADD COLUMN IF NOT EXISTS runtime_mode TEXT NOT NULL DEFAULT '';
