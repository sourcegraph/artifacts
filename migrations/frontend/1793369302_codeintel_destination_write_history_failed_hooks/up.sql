COMMENT ON TABLE codeintel_destination_write_history IS 'Destination writer jobs that ended, with their timings, and upload hooks that failed to write a bundle. The latest written job of a completed upload is kept while the upload exists; other rows are kept for 30 days.';

COMMENT ON COLUMN codeintel_destination_write_history.outcome IS 'How the job ended: written, deleted, dropped, or errored; or failed, for an upload hook that failed to write the bundle of the upload.';

COMMENT ON COLUMN codeintel_destination_write_history.queued_at IS 'Time the job was last queued, or the time a failed upload hook failed.';

COMMENT ON COLUMN codeintel_destination_write_history.failure_message IS 'Most recent failure of the job, or the error of a failed upload hook.';
