CREATE TABLE IF NOT EXISTS own_aggregate_recent_contribution (
    id SERIAL PRIMARY KEY,
    commit_author_id INTEGER NOT NULL REFERENCES commit_authors(id),
    changed_file_path_id INTEGER NOT NULL REFERENCES repo_paths(id),
    contributions_count INTEGER DEFAULT 0,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

CREATE UNIQUE INDEX IF NOT EXISTS own_aggregate_recent_contribution_file_author
    ON own_aggregate_recent_contribution (changed_file_path_id, commit_author_id);

ALTER TABLE own_aggregate_recent_contribution ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON own_aggregate_recent_contribution;
CREATE POLICY tenant_isolation_policy ON own_aggregate_recent_contribution
    USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE TABLE IF NOT EXISTS own_aggregate_recent_view (
    id SERIAL PRIMARY KEY,
    viewer_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE DEFERRABLE,
    viewed_file_path_id INTEGER NOT NULL REFERENCES repo_paths(id),
    views_count INTEGER DEFAULT 0,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

COMMENT ON TABLE own_aggregate_recent_view IS 'One entry contains a number of views of a single file by a given viewer.';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'own_aggregate_recent_view_viewer'
    ) THEN
        IF NOT EXISTS (
            SELECT 1 FROM pg_class WHERE relname = 'own_aggregate_recent_view_viewer'
        ) THEN
            CREATE UNIQUE INDEX own_aggregate_recent_view_viewer
                ON own_aggregate_recent_view (viewed_file_path_id, viewer_id);
        END IF;

        ALTER TABLE own_aggregate_recent_view
            ADD CONSTRAINT own_aggregate_recent_view_viewer UNIQUE USING INDEX own_aggregate_recent_view_viewer;
    END IF;
END;
$$;

ALTER TABLE own_aggregate_recent_view ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON own_aggregate_recent_view;
CREATE POLICY tenant_isolation_policy ON own_aggregate_recent_view
    USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE TABLE IF NOT EXISTS own_signal_configurations (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    excluded_repo_patterns TEXT[],
    enabled BOOLEAN NOT NULL DEFAULT false,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

CREATE UNIQUE INDEX IF NOT EXISTS own_signal_configurations_name_uidx
    ON own_signal_configurations (name, tenant_id);

ALTER TABLE own_signal_configurations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON own_signal_configurations;
CREATE POLICY tenant_isolation_policy ON own_signal_configurations
    USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

INSERT INTO own_signal_configurations (tenant_id, name, description, excluded_repo_patterns, enabled)
SELECT id, 'recent-contributors', 'Indexes contributors in each file using repository history.', NULL, false FROM tenants
ON CONFLICT DO NOTHING;
INSERT INTO own_signal_configurations (tenant_id, name, description, excluded_repo_patterns, enabled)
SELECT id, 'recent-views', 'Indexes users that recently viewed files in Sourcegraph.', NULL, false FROM tenants
ON CONFLICT DO NOTHING;
INSERT INTO own_signal_configurations (tenant_id, name, description, excluded_repo_patterns, enabled)
SELECT id, 'analytics', 'Indexes ownership data to present in aggregated views like Admin > Analytics > Own and Repo > Ownership', NULL, false FROM tenants
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS own_background_jobs (
    id SERIAL PRIMARY KEY,
    state TEXT DEFAULT 'queued',
    failure_message TEXT,
    queued_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    process_after TIMESTAMP WITH TIME ZONE,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    cancel BOOLEAN NOT NULL DEFAULT false,
    repo_id INTEGER NOT NULL,
    job_type INTEGER NOT NULL,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

CREATE INDEX IF NOT EXISTS own_background_jobs_repo_id_idx ON own_background_jobs (repo_id);
CREATE INDEX IF NOT EXISTS own_background_jobs_state_idx ON own_background_jobs (state);

ALTER TABLE own_background_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON own_background_jobs;
CREATE POLICY tenant_isolation_policy ON own_background_jobs
    USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE OR REPLACE VIEW own_background_jobs_config_aware WITH (security_invoker = true) AS
SELECT
    obj.id,
    obj.state,
    obj.failure_message,
    obj.queued_at,
    obj.started_at,
    obj.finished_at,
    obj.process_after,
    obj.num_resets,
    obj.num_failures,
    obj.last_heartbeat_at,
    obj.execution_logs,
    obj.worker_hostname,
    obj.cancel,
    obj.repo_id,
    obj.job_type,
    osc.name AS config_name,
    obj.tenant_id
FROM own_background_jobs obj
JOIN own_signal_configurations osc ON obj.job_type = osc.id
WHERE osc.enabled IS TRUE;

CREATE TABLE IF NOT EXISTS own_signal_recent_contribution (
    id SERIAL PRIMARY KEY,
    commit_author_id INTEGER NOT NULL REFERENCES commit_authors(id),
    changed_file_path_id INTEGER NOT NULL REFERENCES repo_paths(id),
    commit_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    commit_id BYTEA NOT NULL,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

COMMENT ON TABLE own_signal_recent_contribution IS 'One entry per file changed in every commit that classifies as a contribution signal.';

CREATE OR REPLACE FUNCTION update_own_aggregate_recent_contribution() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    WITH RECURSIVE ancestors AS (
        SELECT id, parent_id, 1 AS level
        FROM repo_paths
        WHERE id = NEW.changed_file_path_id
        UNION ALL
        SELECT p.id, p.parent_id, a.level + 1
        FROM repo_paths p
        JOIN ancestors a ON p.id = a.parent_id
    )
    UPDATE own_aggregate_recent_contribution
    SET contributions_count = contributions_count + 1
    WHERE commit_author_id = NEW.commit_author_id AND changed_file_path_id IN (
        SELECT id FROM ancestors
    );

    WITH RECURSIVE ancestors AS (
        SELECT id, parent_id, 1 AS level
        FROM repo_paths
        WHERE id = NEW.changed_file_path_id
        UNION ALL
        SELECT p.id, p.parent_id, a.level + 1
        FROM repo_paths p
        JOIN ancestors a ON p.id = a.parent_id
    )
    INSERT INTO own_aggregate_recent_contribution (commit_author_id, changed_file_path_id, contributions_count)
    SELECT NEW.commit_author_id, id, 1
    FROM ancestors
    WHERE NOT EXISTS (
        SELECT 1 FROM own_aggregate_recent_contribution
        WHERE commit_author_id = NEW.commit_author_id AND changed_file_path_id = ancestors.id
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_own_aggregate_recent_contribution ON own_signal_recent_contribution;
CREATE TRIGGER update_own_aggregate_recent_contribution
    AFTER INSERT ON own_signal_recent_contribution
    FOR EACH ROW EXECUTE FUNCTION update_own_aggregate_recent_contribution();

ALTER TABLE own_signal_recent_contribution ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON own_signal_recent_contribution;
CREATE POLICY tenant_isolation_policy ON own_signal_recent_contribution
    USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
