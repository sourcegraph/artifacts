
ALTER TABLE agent_review_diagnostic_feedback
ADD COLUMN IF NOT EXISTS user_id INTEGER GENERATED ALWAYS AS ((data->'author'->>'user_id')::integer) STORED REFERENCES users(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS agent_review_diagnostic_feedback_user_id ON agent_review_diagnostic_feedback(user_id);
