-- Recreate the entitlement_type enum and convert column back
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entitlement_type') THEN
        CREATE TYPE entitlement_type AS ENUM ('completion_credits', 'deep_search');
    END IF;
END
$$;
ALTER TABLE entitlements ALTER COLUMN type TYPE entitlement_type USING type::entitlement_type;

-- Recreate completion_credits_consumption table
CREATE TABLE IF NOT EXISTS completion_credits_consumption (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    credits BIGINT NOT NULL,
    modelref TEXT NOT NULL,
    feature TEXT NOT NULL,
    interaction_uri TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    tokens JSONB
);

COMMENT ON COLUMN completion_credits_consumption.modelref IS 'The completion modelref that was used';
COMMENT ON COLUMN completion_credits_consumption.feature IS 'The feature that consumed the credits';
COMMENT ON COLUMN completion_credits_consumption.interaction_uri IS 'URI identifying the specific interaction that consumed credits';

CREATE INDEX IF NOT EXISTS completion_credits_consumption_interaction_uri_idx ON completion_credits_consumption (interaction_uri text_pattern_ops);
CREATE INDEX IF NOT EXISTS completion_credits_consumption_modelref_idx ON completion_credits_consumption (modelref text_pattern_ops);

ALTER TABLE completion_credits_consumption ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON completion_credits_consumption;
CREATE POLICY tenant_isolation_policy ON completion_credits_consumption AS PERMISSIVE FOR ALL TO PUBLIC
USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

-- Recreate completion_credits_entitlement_window_usage table
CREATE TABLE IF NOT EXISTS completion_credits_entitlement_window_usage (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entitlement_id INTEGER NOT NULL REFERENCES entitlements(id) ON DELETE CASCADE,
    usage BIGINT,
    limit_exceeded BOOLEAN,
    last_trail_id BIGINT,
    window_started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    PRIMARY KEY (user_id, entitlement_id)
);

ALTER TABLE completion_credits_entitlement_window_usage ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON completion_credits_entitlement_window_usage;
CREATE POLICY tenant_isolation_policy ON completion_credits_entitlement_window_usage AS PERMISSIVE FOR ALL TO PUBLIC
USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
