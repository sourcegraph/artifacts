ALTER TABLE deepsearch_question_jobs
    ADD COLUMN IF NOT EXISTS parent_interaction_id TEXT,
    ADD COLUMN IF NOT EXISTS parent_interaction_root_id TEXT;
