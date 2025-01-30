-- Undo the changes made in the up migration
DROP TABLE IF EXISTS agent_review_diagnostic_feedback CASCADE;

DROP TABLE IF EXISTS agent_reviews_diagnostics CASCADE;

DROP TABLE IF EXISTS agent_reviews CASCADE;
