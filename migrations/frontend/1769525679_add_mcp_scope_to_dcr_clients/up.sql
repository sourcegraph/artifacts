-- Add 'mcp' scope to DCR registered clients that have 'user:all' but not 'mcp'
-- This fixes OAuth authorization failures for older DCR clients when the server
-- advertises the 'mcp' scope in WWW-Authenticate headers
UPDATE idp_clients
SET scopes = array_append(scopes, 'mcp'),
    updated_at = NOW()
WHERE registration_source = 'dcr'
  AND 'user:all' = ANY(scopes)
  AND NOT 'mcp' = ANY(scopes);
