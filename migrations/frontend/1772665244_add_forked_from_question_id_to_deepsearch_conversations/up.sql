ALTER TABLE deepsearch_conversations
    ADD COLUMN IF NOT EXISTS forked_from_question_id INTEGER REFERENCES deepsearch_questions(id) ON DELETE SET NULL;
