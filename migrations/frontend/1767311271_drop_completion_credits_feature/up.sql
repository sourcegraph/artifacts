-- Remove all existing completion_credits entitlements and grants
DELETE FROM entitlement_grants
WHERE entitlement_id IN (
  SELECT id FROM entitlements WHERE type = 'completion_credits'
);

DELETE FROM entitlements
WHERE type = 'completion_credits';

-- Drop completion credits tracking tables
DROP TABLE IF EXISTS completion_credits_entitlement_window_usage CASCADE;
DROP TABLE IF EXISTS completion_credits_consumption CASCADE;

-- Convert entitlements.type from enum to text, as the enum type causes a lot
-- of complications with our backcompat testing.
ALTER TABLE entitlements ALTER COLUMN type TYPE text USING type::text;
DROP TYPE IF EXISTS entitlement_type;
