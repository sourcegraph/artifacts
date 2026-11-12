-- Supports the expired upload janitor (SoftDeleteExpiredUploads), which selects the
-- completed, expired uploads least recently checked for references. Without this
-- index that query sequentially scans all of scip_uploads on every run, even though
-- very few uploads are both completed and expired.
CREATE INDEX CONCURRENTLY IF NOT EXISTS scip_uploads_last_referenced_scan_at
    ON scip_uploads (last_referenced_scan_at NULLS FIRST, finished_at, id)
    WHERE state = 'completed' AND expired;
