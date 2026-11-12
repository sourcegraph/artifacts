-- Index each change request's head branch for search. A branch can be renamed
-- on the code host, so the trigger also watches head_ref.
CREATE OR REPLACE FUNCTION enqueue_change_request_search_index() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE'
        AND OLD.title IS NOT DISTINCT FROM NEW.title
        AND OLD.body IS NOT DISTINCT FROM NEW.body
        AND OLD.repository_name IS NOT DISTINCT FROM NEW.repository_name
        AND OLD.author IS NOT DISTINCT FROM NEW.author
        AND OLD.head_ref IS NOT DISTINCT FROM NEW.head_ref
    THEN
        RETURN NEW;
    END IF;
    INSERT INTO change_request_search_queue (tenant_id, change_request_id)
    VALUES (NEW.tenant_id, NEW.id)
    ON CONFLICT (tenant_id, change_request_id) DO UPDATE SET
        state = 'queued',
        queued_at = now(),
        process_after = NULL,
        started_at = NULL,
        finished_at = NULL,
        failure_message = NULL,
        num_failures = 0,
        num_resets = 0,
        cancel = false;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS change_request_search_index_enqueue ON change_requests;
CREATE TRIGGER change_request_search_index_enqueue
    AFTER INSERT OR UPDATE OF title, body, repository_name, author, head_ref ON change_requests
    FOR EACH ROW EXECUTE FUNCTION enqueue_change_request_search_index();

-- Rebuild the index from scratch so that every entry includes the head branch.
TRUNCATE TABLE change_request_search_queue;
INSERT INTO change_request_search_queue (tenant_id, change_request_id)
SELECT tenant_id, id FROM change_requests;
