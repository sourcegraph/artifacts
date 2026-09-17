-- The in-progress backfill worker dequeues jobs by their parent backfill's
-- estimated cost, then ID. Restrict the ordering index to parents it can see.
CREATE INDEX CONCURRENTLY IF NOT EXISTS insight_series_backfill_processing_order_idx
ON insight_series_backfill (estimated_cost, id)
WHERE state = 'processing';
