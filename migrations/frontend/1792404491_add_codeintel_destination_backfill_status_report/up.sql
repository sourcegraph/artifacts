ALTER TABLE codeintel_destination_backfill_rounds ADD COLUMN IF NOT EXISTS status_reported_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE codeintel_destination_backfill_rounds ADD COLUMN IF NOT EXISTS status_reported_caught_up BOOLEAN;

COMMENT ON COLUMN codeintel_destination_backfill_rounds.status_reported_at IS 'When the backfill status of the tenant was last recorded as a telemetry event.';
COMMENT ON COLUMN codeintel_destination_backfill_rounds.status_reported_caught_up IS 'Whether the backfill had caught up when its status was last recorded; a change is recorded right away.';
