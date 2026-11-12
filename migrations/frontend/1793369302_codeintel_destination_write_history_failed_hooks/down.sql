COMMENT ON TABLE codeintel_destination_write_history IS 'Destination writer jobs that ended, with their timings. The latest written job of a completed upload is kept while the upload exists; other jobs are kept for 30 days.';

COMMENT ON COLUMN codeintel_destination_write_history.outcome IS 'How the job ended: written, deleted, dropped, or errored.';

COMMENT ON COLUMN codeintel_destination_write_history.queued_at IS 'Time the job was last queued.';

COMMENT ON COLUMN codeintel_destination_write_history.failure_message IS 'Most recent failure of the job.';
