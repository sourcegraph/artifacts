ALTER TABLE slack_configurations ADD COLUMN IF NOT EXISTS webhook_verified_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN slack_configurations.webhook_verified_at IS 'Timestamp when Slack successfully verified the events URL by sending a challenge request that we responded to';

UPDATE slack_configurations SET webhook_verified_at = NOW() WHERE webhook_verified_at IS NULL;
