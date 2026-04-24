-- Drop the old unique index that doesn't account for the kind column.
DROP INDEX IF EXISTS user_external_accounts_account;

-- Add a CHECK constraint to enforce valid values for the kind column.
-- We drop first to make this idempotent since PostgreSQL doesn't support
-- ADD CONSTRAINT IF NOT EXISTS.
-- We use NOT VALID to add the constraint without scanning existing rows, which
-- avoids holding an ACCESS EXCLUSIVE lock for the duration of a full table scan.
-- COMMIT AND CHAIN releases the exclusive lock from ADD CONSTRAINT before
-- the validation scan begins.
ALTER TABLE user_external_accounts
    DROP CONSTRAINT IF EXISTS user_external_accounts_kind_valid;
ALTER TABLE user_external_accounts
    ADD CONSTRAINT user_external_accounts_kind_valid
    CHECK (kind IN ('AUTH', 'BATCH_CHANGES')) NOT VALID;

-- Release the ACCESS EXCLUSIVE lock from ADD CONSTRAINT before validation
-- begins. VALIDATE CONSTRAINT only needs a SHARE UPDATE EXCLUSIVE lock,
-- which allows concurrent reads and writes.
COMMIT AND CHAIN;

ALTER TABLE user_external_accounts
    VALIDATE CONSTRAINT user_external_accounts_kind_valid;
