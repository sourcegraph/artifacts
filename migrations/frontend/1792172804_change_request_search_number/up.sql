-- Rebuild the change request search index so that it includes each change
-- request's number. The number never changes, so the trigger does not need to
-- watch it.
TRUNCATE TABLE change_request_search_queue;
INSERT INTO change_request_search_queue (tenant_id, change_request_id)
SELECT tenant_id, id FROM change_requests;
