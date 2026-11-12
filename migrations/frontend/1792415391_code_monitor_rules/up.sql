CREATE TABLE IF NOT EXISTS cm_rules (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    monitor_id BIGINT NOT NULL REFERENCES cm_monitors(id) ON DELETE CASCADE,
    owner_org_id INTEGER REFERENCES orgs(id) ON DELETE SET NULL,
    instructions TEXT NOT NULL,
    review_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    version INTEGER NOT NULL DEFAULT 1,
    UNIQUE (tenant_id, monitor_id)
);

COMMENT ON TABLE cm_rules IS 'Opt-in Code Monitors rules configuration. cm_monitors.namespace_user_id remains the execution identity; owner_org_id is the optional team owner.';

CREATE TABLE IF NOT EXISTS cm_rule_runs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    trigger_id INTEGER NOT NULL REFERENCES cm_trigger_jobs(id) ON DELETE CASCADE,
    configuration JSONB NOT NULL,
    captured BOOLEAN NOT NULL DEFAULT FALSE,
    notifications_enqueued BOOLEAN NOT NULL DEFAULT FALSE,
    state TEXT NOT NULL DEFAULT 'waiting',
    failure_message TEXT,
    queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    process_after TIMESTAMPTZ,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMPTZ,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    cancel BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (tenant_id, trigger_id)
);

-- Foreign-key cascades bypass row-level security, so they cannot use indexes
-- that lead with tenant_id. These indexes lead with the referencing column.
CREATE INDEX IF NOT EXISTS cm_rule_runs_trigger_id ON cm_rule_runs(trigger_id);
CREATE INDEX IF NOT EXISTS cm_rule_runs_dequeue_idx
    ON cm_rule_runs(tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

CREATE TABLE IF NOT EXISTS cm_rule_findings (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    monitor_id BIGINT NOT NULL REFERENCES cm_monitors(id) ON DELETE CASCADE,
    run_id BIGINT NOT NULL REFERENCES cm_rule_runs(id) ON DELETE CASCADE,
    repo_id INTEGER NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    commit_id TEXT NOT NULL,
    match JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verdict TEXT NOT NULL DEFAULT 'pending',
    review JSONB,
    review_error TEXT,
    seen_at TIMESTAMPTZ,
    seen_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE (tenant_id, monitor_id, repo_id, commit_id)
);

COMMENT ON COLUMN cm_rule_findings.seen_at IS 'Shared acknowledgement time. Independent of the automated verdict; NULL means unseen.';
COMMENT ON COLUMN cm_rule_findings.seen_by IS 'User who marked the finding as seen. NULL if unseen or the user was deleted.';

CREATE INDEX IF NOT EXISTS cm_rule_findings_monitor_id ON cm_rule_findings(monitor_id, id DESC);
CREATE INDEX IF NOT EXISTS cm_rule_findings_run_id ON cm_rule_findings(run_id);
CREATE INDEX IF NOT EXISTS cm_rule_findings_repo_id ON cm_rule_findings(repo_id);
CREATE INDEX IF NOT EXISTS cm_rule_findings_seen_by ON cm_rule_findings(seen_by) WHERE seen_by IS NOT NULL;

CREATE TABLE IF NOT EXISTS cm_rule_deliveries (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    run_id BIGINT NOT NULL REFERENCES cm_rule_runs(id) ON DELETE CASCADE,
    notification JSONB NOT NULL,
    state TEXT NOT NULL DEFAULT 'queued',
    failure_message TEXT,
    queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    process_after TIMESTAMPTZ,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMPTZ,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    cancel BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS cm_rule_deliveries_run_id ON cm_rule_deliveries(run_id);
CREATE INDEX IF NOT EXISTS cm_rule_deliveries_dequeue_idx
    ON cm_rule_deliveries(tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

ALTER TABLE cm_rules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON cm_rules;
CREATE POLICY tenant_isolation_policy ON cm_rules AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

ALTER TABLE cm_rule_runs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON cm_rule_runs;
CREATE POLICY tenant_isolation_policy ON cm_rule_runs AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );

ALTER TABLE cm_rule_findings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON cm_rule_findings;
CREATE POLICY tenant_isolation_policy ON cm_rule_findings AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

ALTER TABLE cm_rule_deliveries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON cm_rule_deliveries;
CREATE POLICY tenant_isolation_policy ON cm_rule_deliveries AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );
