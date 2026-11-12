-- Earlier versions do not know the state 'writing': their destination writer
-- never promotes such uploads, and their frontend cannot show them. Queue
-- them for processing again, from the raw upload, which an upload keeps
-- while it is writing. Their pending ingestions wait until processing
-- enqueues them again.
UPDATE scip_uploads
SET state = 'queued', queued_at = clock_timestamp(), started_at = NULL, finished_at = NULL, process_after = NULL
WHERE state = 'writing';
