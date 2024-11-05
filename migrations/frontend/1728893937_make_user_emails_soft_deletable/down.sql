ALTER TABLE ONLY user_emails
    DROP CONSTRAINT user_emails_unique_verified_email;

ALTER TABLE user_emails
    DROP COLUMN IF EXISTS deleted_at;

ALTER TABLE ONLY user_emails
    ADD CONSTRAINT user_emails_unique_verified_email EXCLUDE USING btree(email WITH OPERATOR(=)) WHERE ((verified_at IS NOT NULL));
