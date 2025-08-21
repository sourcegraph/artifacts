CREATE TABLE IF NOT EXISTS deepsearch_questions(
    id serial PRIMARY KEY,
    conversation_id integer NOT NULL REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    data jsonb NOT NULL,
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

ALTER TABLE deepsearch_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_questions;

CREATE POLICY tenant_isolation_policy ON deepsearch_questions AS PERMISSIVE
    FOR ALL TO PUBLIC
        USING ((tenant_id = (
            SELECT
                (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE OR REPLACE FUNCTION update_deepsearch_questions_updated_at()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_deepsearch_questions_updated_at
    BEFORE UPDATE ON deepsearch_questions
    FOR EACH ROW
    EXECUTE FUNCTION update_deepsearch_questions_updated_at();

-- Create index for conversation_id lookups
CREATE INDEX IF NOT EXISTS deepsearch_questions_conversation_id_idx ON deepsearch_questions (conversation_id);

-- Function to update parent conversation updated_at when questions change
CREATE OR REPLACE FUNCTION update_deepsearch_conversation_updated_at_on_question_change()
    RETURNS TRIGGER
    AS $$
BEGIN
    UPDATE deepsearch_conversations 
    SET updated_at = now() 
    WHERE id = COALESCE(NEW.conversation_id, OLD.conversation_id);
    RETURN COALESCE(NEW, OLD);
END;
$$
LANGUAGE plpgsql;

-- Trigger to update conversation updated_at when questions are inserted or updated
CREATE OR REPLACE TRIGGER update_conversation_on_question_change
    AFTER INSERT OR UPDATE ON deepsearch_questions
    FOR EACH ROW
    EXECUTE FUNCTION update_deepsearch_conversation_updated_at_on_question_change();
