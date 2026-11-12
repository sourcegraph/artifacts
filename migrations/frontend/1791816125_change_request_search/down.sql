DROP TRIGGER IF EXISTS change_request_search_index_enqueue ON change_requests;
DROP FUNCTION IF EXISTS enqueue_change_request_search_index();
DROP TABLE IF EXISTS change_request_search_index;
DROP TABLE IF EXISTS change_request_search_queue;
