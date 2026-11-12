DROP TRIGGER IF EXISTS trigger_codeintel_destination_retired_upload ON scip_uploads;
CREATE TRIGGER trigger_codeintel_destination_retired_upload AFTER UPDATE OF state ON scip_uploads FOR EACH ROW
    WHEN (NEW.state IN ('deleting', 'deleted', 'failed', 'superseded', 'canceled')
        AND OLD.state NOT IN ('deleting', 'deleted', 'failed', 'superseded', 'canceled'))
    EXECUTE FUNCTION func_codeintel_destination_retired_upload();

-- The restored trigger retires uploads once they are deleting, so it does not
-- fire when uploads already deleting become deleted. Retire them now, as the
-- trigger would have.
INSERT INTO codeintel_destination_write_jobs (tenant_id, upload_id, op, queued_at, process_after)
SELECT u.tenant_id, u.id, 'delete', NOW(), '-infinity' FROM scip_uploads u WHERE u.state = 'deleting' ORDER BY u.id
ON CONFLICT ON CONSTRAINT codeintel_destination_write_jobs_tenant_id_upload_id_key DO UPDATE SET
    op = 'delete', state = 'queued', num_failures = 0, num_resets = 0, failure_message = NULL,
    queued_at = EXCLUDED.queued_at, started_at = NULL, finished_at = NULL, process_after = EXCLUDED.process_after;
