-- The producer failed the backfill jobs of uploads that are not in the
-- codeintel tables, as it has nothing to backfill them from, and a completed
-- upload that is not there never will be. The planner now plans those uploads
-- as skipped, so their failed jobs are skipped too.
UPDATE codeintel_destination_backfill_jobs
SET state = 'skipped'
WHERE state = 'failed'
    AND failure_message LIKE 'upload % is not in the codeintel tables';

COMMENT ON COLUMN codeintel_destination_backfill_jobs.state IS 'dbworker job state. Uploads that were already written are planned as completed, and uploads that are not in the codeintel tables, which have nothing to backfill, as skipped.';
