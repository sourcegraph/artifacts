ALTER TABLE agent_review_diagnostics ADD COLUMN IF NOT EXISTS quality TEXT GENERATED ALWAYS AS (data->>'quality') STORED;
CREATE INDEX IF NOT EXISTS idx_agent_review_diagnostics_quality ON agent_review_diagnostics (quality);
