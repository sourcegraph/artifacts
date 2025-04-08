-- Undo the changes made in the up migration
ALTER TABLE agent_review_diagnostic_feedback DROP CONSTRAINT IF EXISTS check_confusion_label;
ALTER TABLE agent_review_diagnostic_feedback DROP CONSTRAINT IF EXISTS check_helpfulness_label;
