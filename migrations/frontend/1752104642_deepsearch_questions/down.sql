DROP TABLE IF EXISTS deepsearch_questions CASCADE;

DROP FUNCTION IF EXISTS update_deepsearch_questions_updated_at();

DROP TRIGGER IF EXISTS update_deepsearch_questions_updated_at ON deepsearch_questions;

DROP FUNCTION IF EXISTS update_deepsearch_conversation_updated_at_on_question_change();

DROP TRIGGER IF EXISTS update_conversation_on_question_change ON deepsearch_questions;
