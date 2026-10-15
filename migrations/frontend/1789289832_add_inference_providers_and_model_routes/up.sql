CREATE TABLE IF NOT EXISTS inference_providers (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    name TEXT NOT NULL,
    kind TEXT NOT NULL,
    automatic_coverage BOOLEAN NOT NULL DEFAULT FALSE,
    config BYTEA NOT NULL,
    encryption_key_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT inference_providers_unique_name UNIQUE (tenant_id, name)
);

ALTER TABLE inference_providers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON inference_providers;
CREATE POLICY tenant_isolation_policy ON inference_providers AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE UNIQUE INDEX IF NOT EXISTS inference_providers_unique_automatic_coverage_kind
    ON inference_providers (tenant_id, kind) WHERE automatic_coverage;

CREATE TABLE IF NOT EXISTS inference_model_routes (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    model_ref TEXT NOT NULL,
    provider_id BIGINT NOT NULL REFERENCES inference_providers(id) ON DELETE CASCADE,
    route_type TEXT NOT NULL,
    upstream_model TEXT
);

ALTER TABLE inference_model_routes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON inference_model_routes;
CREATE POLICY tenant_isolation_policy ON inference_model_routes AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE INDEX IF NOT EXISTS inference_model_routes_provider_id_idx
    ON inference_model_routes (provider_id);

CREATE UNIQUE INDEX IF NOT EXISTS inference_model_routes_unique_explicit_model
    ON inference_model_routes (tenant_id, model_ref) WHERE route_type = 'explicit';

CREATE UNIQUE INDEX IF NOT EXISTS inference_model_routes_unique_exclusion
    ON inference_model_routes (tenant_id, provider_id, model_ref) WHERE route_type = 'exclusion';

CREATE TABLE IF NOT EXISTS inference_routing_configuration (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    fallback_mode TEXT NOT NULL DEFAULT 'sourcegraph',
    fallback_models JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT inference_routing_configuration_unique_tenant UNIQUE (tenant_id)
);

ALTER TABLE inference_routing_configuration ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON inference_routing_configuration;
CREATE POLICY tenant_isolation_policy ON inference_routing_configuration AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
