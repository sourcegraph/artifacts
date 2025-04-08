UPDATE agent_reviews
SET data = jsonb_set(
    data - 'rules_applied',
    '{rules_applied_deprecated}',
    data->'rules_applied'
)
WHERE data ? 'rules_applied';
