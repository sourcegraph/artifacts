CREATE TABLE IF NOT EXISTS deepsearch_conversations(
    id serial PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    edit_token uuid DEFAULT gen_random_uuid(),
    read_token uuid DEFAULT gen_random_uuid(),
    user_id integer REFERENCES users(id) ON DELETE CASCADE,
    data jsonb,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant') ::integer
);

ALTER TABLE deepsearch_conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_conversations;

CREATE POLICY tenant_isolation_policy ON deepsearch_conversations AS PERMISSIVE
    FOR ALL TO PUBLIC
        USING ((tenant_id =(
            SELECT
                (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE OR REPLACE FUNCTION update_deepsearch_conversations_updated_at()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_deepsearch_conversations_updated_at
    BEFORE UPDATE ON deepsearch_conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_deepsearch_conversations_updated_at();
