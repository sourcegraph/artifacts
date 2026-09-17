-- State-first replacements were created before removing these indexes.
DROP INDEX IF EXISTS diff_tours_dequeue_idx;
DROP INDEX IF EXISTS deepsearch_question_jobs_dequeue_idx;
DROP INDEX IF EXISTS deepsearch_search_queue_dequeue_idx;
