DROP TRIGGER IF EXISTS deepsearch_questions_search_queue_trg ON deepsearch_questions;
DROP FUNCTION IF EXISTS deepsearch_enqueue_question_for_search();
DROP TABLE IF EXISTS deepsearch_search_index;
DROP TABLE IF EXISTS deepsearch_search_queue;
