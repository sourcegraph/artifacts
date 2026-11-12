ALTER TABLE change_request_review_threads DROP COLUMN IF EXISTS node_id;
ALTER TABLE change_requests DROP COLUMN IF EXISTS external_node_id;
