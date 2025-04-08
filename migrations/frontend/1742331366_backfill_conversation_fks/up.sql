UPDATE
    agent_conversations ac
SET
    data = jsonb_set(ac.data, '{changeset_id}', to_jsonb(ch.id))
FROM
    agent_changesets ch
WHERE
    ac.changeset_id IS NULL
    AND ac.pull_request_id::text = ch.external_service_id
    AND ac.tenant_id = ch.tenant_id;

WITH conversation_repo_urls AS (
    SELECT
        id,
        regexp_replace(regexp_replace(external_html_url, '^https?://([^/]+)/(.+?)(?:/pull|/issues|#|$).*', '\1/\2'), '/+$', '') AS repo_name
    FROM
        agent_conversations)
UPDATE
    agent_conversations
SET
    data = jsonb_set(data, '{repo_id}', to_jsonb(r.id))
FROM
    conversation_repo_urls c
    JOIN repo r ON r.name = c.repo_name
        AND r.tenant_id = tenant_id;
