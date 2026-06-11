ALTER TABLE deepsearch_question_jobs
    ADD COLUMN IF NOT EXISTS request_client JSONB;
