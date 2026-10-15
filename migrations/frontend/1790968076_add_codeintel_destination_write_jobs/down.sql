DROP TRIGGER IF EXISTS trigger_codeintel_destination_deleted_uploads ON scip_uploads;
DROP TRIGGER IF EXISTS trigger_codeintel_destination_retired_upload ON scip_uploads;
DROP FUNCTION IF EXISTS func_codeintel_destination_deleted_uploads();
DROP FUNCTION IF EXISTS func_codeintel_destination_retired_upload();
DROP TABLE IF EXISTS codeintel_destination_write_jobs;
