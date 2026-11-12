-- The existing manifest columns remain the latest publication. The active
-- columns select the generation replicas may serve; NULL means the authority
-- exists but no generation has been activated yet.
-- Backfill only when introducing the columns. Reapplying the migration must
-- never activate a first publication that is still waiting for replication.
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = current_schema() AND table_name = 'gitserver_continuity_manifests'
            AND column_name = 'active_generation'
    ) THEN
        ALTER TABLE gitserver_continuity_manifests ADD COLUMN active_generation BIGINT;
        ALTER TABLE gitserver_continuity_manifests ADD COLUMN active_manifest_digest TEXT;
        ALTER TABLE gitserver_continuity_manifests ADD COLUMN active_manifest_key TEXT;
        UPDATE gitserver_continuity_manifests SET
            active_generation = generation,
            active_manifest_digest = manifest_digest,
            active_manifest_key = manifest_key;
    END IF;
END $$;
-- Per-shard readiness for the pending latest generation. Keeping it in the
-- authority row serializes acknowledgement, withdrawal, and activation on one
-- row lock.
ALTER TABLE gitserver_continuity_manifests ADD COLUMN IF NOT EXISTS activation_readiness JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE gitserver_continuity_manifests DROP CONSTRAINT IF EXISTS gitserver_continuity_manifests_active_check;
ALTER TABLE gitserver_continuity_manifests ADD CONSTRAINT gitserver_continuity_manifests_active_check CHECK (
    (active_generation IS NULL AND active_manifest_digest IS NULL AND active_manifest_key IS NULL)
    OR (
        active_generation IS NOT NULL AND active_generation > 0
        AND active_generation <= generation
        AND active_manifest_digest IS NOT NULL
        AND active_manifest_key IS NOT NULL
    )
);
ALTER TABLE gitserver_continuity_manifests DROP CONSTRAINT IF EXISTS gitserver_continuity_manifests_readiness_check;
ALTER TABLE gitserver_continuity_manifests ADD CONSTRAINT gitserver_continuity_manifests_readiness_check CHECK (
    jsonb_typeof(activation_readiness) = 'object'
);

-- The current process incarnation of each gitserver shard. Readiness recorded
-- by any other incarnation of the shard is fenced.
CREATE TABLE IF NOT EXISTS gitserver_continuity_replica_sessions (
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    shard TEXT NOT NULL CHECK (shard <> ''),
    incarnation TEXT NOT NULL CHECK (incarnation <> ''),
    registered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT gitserver_continuity_replica_sessions_pkey PRIMARY KEY (tenant_id, shard)
);

ALTER TABLE gitserver_continuity_replica_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON gitserver_continuity_replica_sessions;
CREATE POLICY tenant_isolation_policy ON gitserver_continuity_replica_sessions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
