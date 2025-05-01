ALTER TABLE agent_reviews ADD COLUMN IF NOT EXISTS repo_id INTEGER GENERATED ALWAYS AS ((data->'request'->'diff'->>'repo_id')::integer) STORED REFERENCES repo(id) ON DELETE CASCADE;

-- Update old agent_reviews rows to include a repo_id property based on the
-- matching name. This allows us to enforce repo permissions based on repo.id
-- going forward even for older reviews that only had repo names.
WITH repo_ids AS (
    SELECT
        ar.id as review_id,
        r.id as repo_id
    FROM agent_reviews ar
    JOIN repo r ON r.name = (ar.data->'request'->'diff'->>'repo') AND r.tenant_id = ar.tenant_id
    WHERE ar.data->>'repo_id' IS NULL
)
UPDATE agent_reviews ar
SET data = jsonb_set(data, '{request,diff,repo_id}', to_jsonb(ri.repo_id))
FROM repo_ids ri
WHERE ar.id = ri.review_id;

-- The goapi.Review struct had a `repo_id` field, but we never populated. This should
-- be a no-op, but we'll do it anyway to avoid confusion about whether we use .repo_id
-- or .request.diff.repo_id.
UPDATE agent_reviews
SET data = jsonb_set(data, '{repo_id}', 'null');
