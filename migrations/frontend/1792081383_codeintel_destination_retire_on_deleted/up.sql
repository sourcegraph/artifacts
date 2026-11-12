-- An upload is retired once it is deleted, failed, superseded or canceled; the
-- destination must not serve it. A deleting upload is still visible to code
-- navigation until the commit graph update marks it deleted, so the
-- destination keeps serving it until then, like the legacy tables do.
DROP TRIGGER IF EXISTS trigger_codeintel_destination_retired_upload ON scip_uploads;
CREATE TRIGGER trigger_codeintel_destination_retired_upload AFTER UPDATE OF state ON scip_uploads FOR EACH ROW
    WHEN (NEW.state IN ('deleted', 'failed', 'superseded', 'canceled')
        AND OLD.state NOT IN ('deleted', 'failed', 'superseded', 'canceled'))
    EXECUTE FUNCTION func_codeintel_destination_retired_upload();
