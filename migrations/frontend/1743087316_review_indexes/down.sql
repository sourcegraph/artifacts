DROP INDEX IF EXISTS idx_agent_reviews_created_at;
DROP INDEX IF EXISTS idx_agent_review_diagnostics_created_at;
DROP INDEX IF EXISTS idx_agent_review_diagnostics_rule_id;
DROP INDEX IF EXISTS idx_agent_review_diagnostics_severity;
ALTER TABLE agent_review_diagnostics DROP COLUMN IF EXISTS severity;
