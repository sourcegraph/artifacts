-- Remove 'mcp' scope from DCR registered clients that have both 'user:all' and 'mcp'
-- The only way a client can have both is via the up migration
UPDATE idp_clients
SET scopes = array_remove(scopes, 'mcp'),
    updated_at = NOW()
WHERE registration_source = 'dcr'
  AND 'user:all' = ANY(scopes)
  AND 'mcp' = ANY(scopes);
