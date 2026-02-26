CREATE TABLE IF NOT EXISTS abc_iteration_items (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    iterator_id TEXT NOT NULL,
    item_data TEXT NOT NULL,
    workflow_instance_id BIGINT REFERENCES abc_workflow_instances(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS abc_iteration_items_tenant_id_idx ON abc_iteration_items(tenant_id);
CREATE INDEX IF NOT EXISTS abc_iteration_items_iterator_id_idx ON abc_iteration_items(tenant_id, iterator_id);
CREATE INDEX IF NOT EXISTS abc_iteration_items_workflow_instance_idx ON abc_iteration_items(tenant_id, workflow_instance_id);

ALTER TABLE abc_iteration_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON abc_iteration_items;
CREATE POLICY tenant_isolation_policy ON abc_iteration_items AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
