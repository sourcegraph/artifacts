UPDATE agent_runs
SET parameters = parameters || '{"changeset_event": {"external_service_type": "github"}}'
WHERE parameters->>'type' = 'changeset_event' and parameters->'changeset_event' is not null and parameters->'changeset_event'->>'external_service_type' = '';
