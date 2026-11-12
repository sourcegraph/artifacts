-- Gitserver continuity replicas list the publications awaiting activation every
-- second. Few rows are pending at a time, so index only those rather than
-- scanning every repository of the tenant.
CREATE INDEX CONCURRENTLY IF NOT EXISTS gitserver_continuity_manifests_pending
    ON gitserver_continuity_manifests (tenant_id)
    WHERE active_generation IS DISTINCT FROM generation;
