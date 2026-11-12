-- Service accounts were never granted the DEEP_SEARCH namespace, but MCP did not
-- enforce it, so service accounts with MCP access use Deep Search through MCP.
-- Grant the permissions to SERVICE_ACCOUNT roles that can use MCP before MCP
-- starts enforcing them. MCP was the only way service accounts could use Deep
-- Search, so roles without MCP access are left alone.
--
-- Permission rows are created by rbac.UpdatePermissions at frontend startup,
-- after migrations run. So:
--  * On fresh installs (and new tenants) no DEEP_SEARCH rows exist yet, so this
--    is a no-op and service accounts keep their restrictive default.
--  * On upgrades from before MCP#ACCESS existed, startup will grandfather
--    MCP#ACCESS to SERVICE_ACCOUNT, so treat a missing MCP#ACCESS row as access.
INSERT INTO role_permissions (role_id, permission_id, tenant_id)
SELECT
    r.id, p.id, r.tenant_id
FROM roles AS r
JOIN permissions AS p ON p.tenant_id = r.tenant_id
WHERE r.system
    AND r.name = 'SERVICE_ACCOUNT'
    AND p.namespace = 'DEEP_SEARCH'
    AND p.action IN ('READ', 'WRITE')
    AND (
        EXISTS (
            SELECT 1
            FROM role_permissions AS rp
            JOIN permissions AS mcp ON mcp.id = rp.permission_id
            WHERE rp.role_id = r.id
                AND mcp.namespace = 'MCP'
                AND mcp.action = 'ACCESS'
        )
        OR NOT EXISTS (
            SELECT 1
            FROM permissions AS mcp
            WHERE mcp.tenant_id = r.tenant_id
                AND mcp.namespace = 'MCP'
                AND mcp.action = 'ACCESS'
        )
    )
ON CONFLICT DO NOTHING;
