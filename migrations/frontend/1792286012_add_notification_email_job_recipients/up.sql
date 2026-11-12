ALTER TABLE notification_email_jobs
    ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;

COMMENT ON COLUMN notification_email_jobs.user_id IS 'Recipient of the email.';

-- Jobs queued before recipients were recorded only exist for user-scoped
-- notifications, whose user is the recipient.
UPDATE notification_email_jobs
SET user_id = notifications.user_id
FROM notifications
WHERE notifications.id = notification_email_jobs.notification_id
    AND notification_email_jobs.user_id IS NULL;

DELETE FROM notification_email_jobs WHERE user_id IS NULL;

ALTER TABLE notification_email_jobs ALTER COLUMN user_id SET NOT NULL;
