ALTER TABLE access_requests DROP CONSTRAINT IF EXISTS access_requests_email_key CASCADE;
DROP INDEX IF EXISTS access_requests_email_key CASCADE;
ALTER TABLE access_requests ADD CONSTRAINT access_requests_email_key UNIQUE(email);
