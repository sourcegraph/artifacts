ALTER TABLE agent_review_diagnostic_feedback
ADD COLUMN IF NOT EXISTS review_id INTEGER GENERATED ALWAYS AS ((data->>'review_id')::integer) STORED REFERENCES agent_reviews(id) ON DELETE CASCADE;

-- we don't need to migrate the data as whatever is in the blob should be the source of truth
ALTER TABLE agent_review_diagnostic_feedback
ADD COLUMN diagnostic_id_generated INTEGER GENERATED ALWAYS AS ((data->>'diagnostic_id')::integer) STORED REFERENCES agent_review_diagnostics(id) ON DELETE CASCADE;

ALTER TABLE agent_review_diagnostic_feedback
DROP COLUMN diagnostic_id;

ALTER TABLE agent_review_diagnostic_feedback
RENAME COLUMN diagnostic_id_generated TO diagnostic_id;

-- Do the same thing for agent_review_diagnostics

ALTER TABLE agent_review_diagnostics
ADD COLUMN review_id_generated INTEGER GENERATED ALWAYS AS ((data->>'review_id')::integer) STORED REFERENCES agent_reviews(id) ON DELETE CASCADE;

ALTER TABLE agent_review_diagnostics
DROP COLUMN review_id;

ALTER TABLE agent_review_diagnostics
RENAME COLUMN review_id_generated TO review_id;

-- Create missing indexes
CREATE INDEX IF NOT EXISTS agent_review_diagnostics_review_id ON agent_review_diagnostics(review_id);
CREATE INDEX IF NOT EXISTS agent_review_diagnostic_feedback_diagnostic_id ON agent_review_diagnostic_feedback(diagnostic_id);
CREATE INDEX IF NOT EXISTS agent_review_diagnostic_feedback_review_id ON agent_review_diagnostic_feedback(review_id);
