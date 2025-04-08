-- Change the limit column from bigint back to integer
-- Note: This might cause data loss if any values exceed the integer range
ALTER TABLE entitlements ALTER COLUMN "limit" TYPE integer;
