CREATE TABLE IF NOT EXISTS auth_provider_wizard_drafts (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    
    created_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    wizard_type TEXT NOT NULL,
    
    display_name TEXT,
    
    step_configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    last_validation_result JSONB,
    last_validated_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS auth_provider_wizard_drafts_tenant_user_idx 
    ON auth_provider_wizard_drafts (tenant_id, created_by_user_id);

CREATE INDEX IF NOT EXISTS auth_provider_wizard_drafts_updated_at_idx 
    ON auth_provider_wizard_drafts (tenant_id, updated_at DESC);

ALTER TABLE auth_provider_wizard_drafts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON auth_provider_wizard_drafts;
CREATE POLICY tenant_isolation_policy ON auth_provider_wizard_drafts AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
