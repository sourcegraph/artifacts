DROP INDEX IF EXISTS change_requests_author_login_idx;
DROP INDEX IF EXISTS change_requests_author_external_id_idx;
DROP INDEX IF EXISTS change_requests_author_email_idx;

ALTER TABLE change_requests
    DROP COLUMN IF EXISTS author_normalized,
    DROP COLUMN IF EXISTS author_email,
    DROP COLUMN IF EXISTS author_external_id;
