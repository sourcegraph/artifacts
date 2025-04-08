-- Undo the changes made in the up migration

UPDATE agent_reviews
SET data = jsonb_set(
    data - 'rules_applied_deprecated',
    '{rules_applied}',
    data->'rules_applied_deprecated'
)
WHERE data ? 'rules_applied_deprecated';
