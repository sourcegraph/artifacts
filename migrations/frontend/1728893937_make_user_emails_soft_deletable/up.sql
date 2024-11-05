ALTER TABLE ONLY user_emails
    DROP CONSTRAINT user_emails_unique_verified_email;

ALTER TABLE user_emails
    ADD COLUMN IF NOT EXISTS deleted_at timestamp with time zone DEFAULT NULL;

ALTER TABLE ONLY user_emails
    ADD CONSTRAINT user_emails_unique_verified_email EXCLUDE USING btree(email WITH OPERATOR(=)) WHERE ((verified_at IS NOT NULL AND deleted_at IS NULL));
