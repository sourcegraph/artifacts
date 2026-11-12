-- Skipped jobs stay skipped: older planners and status reports count them as
-- done, as they count completed jobs.
COMMENT ON COLUMN codeintel_destination_backfill_jobs.state IS 'dbworker job state. Uploads that were already written are planned as completed.';
