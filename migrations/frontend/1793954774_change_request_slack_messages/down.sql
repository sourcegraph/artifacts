COMMENT ON TABLE change_request_review_notification_jobs IS NULL;

ALTER TABLE change_request_review_notification_jobs
    DROP COLUMN IF EXISTS recipient_user_id,
    DROP COLUMN IF EXISTS slack_configuration_id,
    DROP COLUMN IF EXISTS slack_channel_id,
    DROP COLUMN IF EXISTS slack_message_ts,
    DROP COLUMN IF EXISTS slack_message_status;
