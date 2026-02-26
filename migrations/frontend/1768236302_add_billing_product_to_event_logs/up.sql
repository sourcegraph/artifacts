ALTER TABLE IF EXISTS event_logs
    ADD COLUMN IF NOT EXISTS billing_product text;
