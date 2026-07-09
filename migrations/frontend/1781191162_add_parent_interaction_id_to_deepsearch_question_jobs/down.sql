ALTER TABLE deepsearch_question_jobs
    DROP COLUMN IF EXISTS parent_interaction_id,
    DROP COLUMN IF EXISTS parent_interaction_root_id;
