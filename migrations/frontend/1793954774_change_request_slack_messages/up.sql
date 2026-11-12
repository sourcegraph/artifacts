-- The review request message that a reviewer job sent in Slack, so that it
-- can be updated when its change request is approved, merged or closed.
ALTER TABLE change_request_review_notification_jobs
    ADD COLUMN IF NOT EXISTS recipient_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS slack_configuration_id INTEGER REFERENCES slack_configurations(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS slack_channel_id TEXT,
    ADD COLUMN IF NOT EXISTS slack_message_ts TEXT,
    ADD COLUMN IF NOT EXISTS slack_message_status TEXT;

COMMENT ON TABLE change_request_review_notification_jobs IS 'Queues notifications about review requests, and records the Slack message that each reviewer job sent. Jobs that sent a message are kept until their change request is merged, so that the message can be updated.';
COMMENT ON COLUMN change_request_review_notification_jobs.slack_message_status IS 'The change request status that the Slack message shows: requested, approved, merged or closed. NULL if unknown.';
