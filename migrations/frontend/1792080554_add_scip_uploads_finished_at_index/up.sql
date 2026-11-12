-- Supports the commit graph fast path reporter, which selects completed uploads
-- by a finished_at window. Without this index that query sequentially scans all
-- of scip_uploads, which on large instances exceeds its statement timeout.
CREATE INDEX CONCURRENTLY IF NOT EXISTS scip_uploads_finished_at
    ON scip_uploads (finished_at)
    WHERE state = 'completed';
