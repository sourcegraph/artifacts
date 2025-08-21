-- Create enum type for deepsearch question status
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'deepsearch_question_status') THEN
        CREATE TYPE deepsearch_question_status AS ENUM ('processing', 'completed', 'cancelled');
    END IF;
END $$;

-- Add status column to deepsearch_questions table
ALTER TABLE deepsearch_questions ADD COLUMN IF NOT EXISTS status deepsearch_question_status DEFAULT 'processing';

-- Populate status column based on existing completed field in data
-- Set completed questions
UPDATE deepsearch_questions 
SET status = 'completed' 
WHERE (data->>'completed')::boolean = true;

-- Set cancelled questions (those with completed=true and cancelled error)
UPDATE deepsearch_questions 
SET status = 'cancelled' 
WHERE (data->>'completed')::boolean = true 
  AND data->'error'->>'kind' = 'Cancelled';
