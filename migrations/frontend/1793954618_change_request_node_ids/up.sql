ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS external_node_id text;
COMMENT ON COLUMN change_requests.external_node_id IS 'The code host''s GraphQL global object ID of the change request (GitHub: node ID; GitLab: Global ID). Refreshed on every sync; NULL if the code host has none.';

-- Temporary: a later migration copies node_id into external_id and drops it.
ALTER TABLE change_request_review_threads ADD COLUMN IF NOT EXISTS node_id text;
