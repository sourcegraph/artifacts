-- Distinguishes a requester-local denial from a genuine generation failure.
-- diff_tours rows are shared per comparison, so a requester-local denial must
-- not poison the row for other, eligible requesters: Enqueue re-queues a failed
-- row whose failure_kind is a requester-local kind. NULL means either no failure
-- or a genuine generation failure, which stays sticky-shared. The set of kinds
-- is defined in application code (see internal/difftour).
ALTER TABLE diff_tours
    ADD COLUMN IF NOT EXISTS failure_kind TEXT;

COMMENT ON COLUMN diff_tours.failure_kind IS 'Kind of the recorded failure, for a requester-local denial that Enqueue re-queues for a later requester; NULL for no failure or a genuine, sticky-shared generation failure. Values are defined in application code (see internal/difftour).';
