ALTER TABLE agent_review_diagnostics
    ALTER COLUMN review_id DROP EXPRESSION IF EXISTS,
    ALTER COLUMN review_id SET NOT NULL;

ALTER TABLE agent_review_diagnostic_feedback
    ALTER COLUMN diagnostic_id DROP EXPRESSION IF EXISTS,
    ALTER COLUMN diagnostic_id SET NOT NULL,
    DROP COLUMN IF EXISTS review_id;

DO $$
BEGIN
    ALTER TABLE agent_review_diagnostic_feedback
    ADD CONSTRAINT agent_review_diagnostic_feedback_diagnostic_id_fkey
    FOREIGN KEY (diagnostic_id)
    REFERENCES agent_review_diagnostics(id)
    ON DELETE CASCADE;
EXCEPTION
    WHEN duplicate_object OR duplicate_table OR invalid_table_definition THEN
        RAISE NOTICE 'Constraint already exists, ignoring...';
END;
$$;

ALTER TABLE agent_review_diagnostic_feedback
    DROP CONSTRAINT IF EXISTS agent_review_diagnostic_feedback_diagnostic_id_generated_fkey;

ALTER TABLE agent_review_diagnostics
    DROP CONSTRAINT IF EXISTS agent_review_diagnostics_review_id_generated_fkey;

DROP INDEX IF EXISTS agent_review_diagnostics_review_id;
DROP INDEX IF EXISTS agent_review_diagnostic_feedback_diagnostic_id;
DROP INDEX IF EXISTS agent_review_diagnostic_feedback_review_id;
