-- These indexes should be small because we don't have any massive adoption of agents yet.
CREATE INDEX IF NOT EXISTS idx_agent_reviews_created_at ON agent_reviews (created_at);
CREATE INDEX IF NOT EXISTS idx_agent_review_diagnostics_created_at ON agent_review_diagnostics (created_at);
CREATE INDEX IF NOT EXISTS idx_agent_review_diagnostics_rule_id ON agent_review_diagnostics (rule_id);
ALTER TABLE agent_review_diagnostics ADD COLUMN IF NOT EXISTS severity TEXT GENERATED ALWAYS AS (data->>'severity') STORED;
CREATE INDEX IF NOT EXISTS idx_agent_review_diagnostics_severity ON agent_review_diagnostics (severity);
