ALTER TABLE generic_agent_questions
    ADD COLUMN IF NOT EXISTS turns JSONB NOT NULL DEFAULT '[]'::jsonb;
