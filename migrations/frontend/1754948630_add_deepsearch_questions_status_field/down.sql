-- Remove the status column
ALTER TABLE deepsearch_questions DROP COLUMN IF EXISTS status;

-- Drop the enum type
DROP TYPE IF EXISTS deepsearch_question_status;
