-- Reverse the rename: 'ENTITLEMENTS' -> 'ENTITLEMENT'. Updating in place
-- preserves permission row IDs and any existing role assignments.
UPDATE permissions
SET namespace = 'ENTITLEMENT'
WHERE namespace = 'ENTITLEMENTS';
