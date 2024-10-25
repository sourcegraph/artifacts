ALTER TABLE access_requests DROP CONSTRAINT IF EXISTS access_requests_email_key;
CREATE UNIQUE INDEX IF NOT EXISTS access_requests_email_key ON access_requests (email) WHERE status = 'PENDING';
