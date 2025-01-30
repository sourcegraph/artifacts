-- Agents
CREATE TABLE IF NOT EXISTS agents
(
    id                 SERIAL PRIMARY KEY,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    tenant_id          INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    -- owner_user_id is nullable to allow deleting user accounts without cascade deleting agents.
    owner_user_id      INTEGER,
    title              TEXT NOT NULL,
    description        TEXT,

    CONSTRAINT agents_title_length_check CHECK (length(title) > 2 AND length(title) <= 200),
    CONSTRAINT agents_description_length_check CHECK (length(description) <= 3000),

    FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE
);


ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agents;
CREATE POLICY tenant_isolation_policy ON agents AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));


CREATE INDEX IF NOT EXISTS agents_tenant_id_idx ON agents (tenant_id);

-- Agent Connections
CREATE TABLE IF NOT EXISTS agent_connections
(
    id                   SERIAL PRIMARY KEY,
    tenant_id            INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    agent_id             INTEGER NOT NULL,
    type                 TEXT NOT NULL,

    github_app_id        INTEGER,
    webhook_id           INTEGER,

    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    FOREIGN KEY (github_app_id) REFERENCES github_apps(id) ON DELETE SET NULL DEFERRABLE,
    FOREIGN KEY (webhook_id) REFERENCES webhooks(id) ON DELETE SET NULL DEFERRABLE,
    CONSTRAINT agent_connections_type_check CHECK (type IN ('github_app', 'github_webhook', 'gitlab_webhook'))
);

ALTER TABLE agent_connections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_connections;
CREATE POLICY tenant_isolation_policy ON agent_connections USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));


CREATE INDEX IF NOT EXISTS agent_connections_agent_id_idx ON agent_connections (agent_id);
CREATE INDEX IF NOT EXISTS agent_connections_tenant_id_idx ON agent_connections (tenant_id);
CREATE INDEX IF NOT EXISTS agent_connections_github_app_id_idx ON agent_connections (github_app_id);
CREATE INDEX IF NOT EXISTS agent_connections_webhook_id_idx ON agent_connections (webhook_id);

-- Agent Programs
CREATE TABLE IF NOT EXISTS agent_programs
(
    id                 SERIAL PRIMARY KEY,
    tenant_id          INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    created_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    agent_id           INTEGER NOT NULL,
    status             TEXT NOT NULL,
    -- NOTE(olafurpg): storing all the files as JSON is inefficient, but it's
    -- super easy to implement.  to get the proof-of-concept working. I spent a
    -- moment designing a git-like system where we have branches, commits, etc,
    -- but there are non-trivial challenges to making that work (content addressed
    -- files requires reference counting, among other things).
    -- Before going down that path, let's keep it simple, and validate the market
    -- demand for agent programs.
    files              JSONB NOT NULL,

    FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE,
    CONSTRAINT agent_programs_status_check CHECK (status IN ('enabled', 'disabled'))
);


ALTER TABLE agent_programs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_programs;
CREATE POLICY tenant_isolation_policy ON agent_programs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE INDEX IF NOT EXISTS agent_programs_agent_id_idx ON agent_programs (agent_id);
CREATE INDEX IF NOT EXISTS agent_programs_tenant_id_idx ON agent_programs (tenant_id);
