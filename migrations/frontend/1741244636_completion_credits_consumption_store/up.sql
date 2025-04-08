CREATE TABLE IF NOT EXISTS completion_credits_consumption (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    credits BIGINT NOT NULL,
    modelref TEXT NOT NULL,
    feature TEXT NOT NULL,
    interaction_uri TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

COMMENT ON COLUMN completion_credits_consumption.modelref IS 'The completion modelref that was used';
COMMENT ON COLUMN completion_credits_consumption.feature IS 'The feature that consumed the credits';
COMMENT ON COLUMN completion_credits_consumption.interaction_uri IS 'URI identifying the specific interaction that consumed credits';

-- From Cody:
-- This index uses text_pattern_ops operator class which is optimized for pattern
-- matching operations (LIKE and ~ queries) that don't need to be case-sensitive.
-- It will significantly speed up queries that use LIKE with right-side wildcards
-- (e.g., WHERE interaction_uri LIKE 'prefix%') while maintaining good insert performance.
CREATE INDEX IF NOT EXISTS completion_credits_consumption_interaction_uri_idx ON completion_credits_consumption (interaction_uri text_pattern_ops);
CREATE INDEX IF NOT EXISTS completion_credits_consumption_modelref_idx ON completion_credits_consumption (modelref text_pattern_ops);

-- Enable RLS on both tables
ALTER TABLE completion_credits_consumption ENABLE ROW LEVEL SECURITY;

-- Create tenant isolation policies
DROP POLICY IF EXISTS tenant_isolation_policy ON completion_credits_consumption;
CREATE POLICY tenant_isolation_policy ON completion_credits_consumption AS PERMISSIVE FOR ALL TO PUBLIC
USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
