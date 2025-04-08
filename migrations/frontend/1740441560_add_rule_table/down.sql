DROP TABLE IF EXISTS agent_rules CASCADE;
DROP TABLE IF EXISTS agent_rule_revisions CASCADE;
ALTER TABLE agent_review_diagnostics DROP COLUMN IF EXISTS rule_id;
ALTER TABLE agent_review_diagnostics DROP COLUMN IF EXISTS rule_revision_id;
ALTER TABLE agent_review_diagnostics DROP COLUMN IF EXISTS rule_uri;
