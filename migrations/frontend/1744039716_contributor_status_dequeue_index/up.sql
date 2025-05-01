CREATE INDEX IF NOT EXISTS contributor_jobs_dequeue_idx ON contributor_jobs
    USING btree (state, queued_at, id)
    INCLUDE (process_after)
    WHERE state IN ('queued', 'errored');
