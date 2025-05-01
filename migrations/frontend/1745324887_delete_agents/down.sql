-- This migration is not idempotent in the traditional sense since we just
-- re-run the drop migration. This is fine since agents were not widely
-- productionized.
DROP TABLE IF EXISTS agents CASCADE;
DROP TABLE IF EXISTS agent_conversations CASCADE;
DROP TABLE IF EXISTS agent_rules CASCADE;
DROP TABLE IF EXISTS agent_changeset_revisions CASCADE;
DROP TABLE IF EXISTS agent_changesets CASCADE;
DROP TABLE IF EXISTS agent_connections CASCADE;
DROP TABLE IF EXISTS agent_conversation_message_chunks CASCADE;
DROP TABLE IF EXISTS agent_conversation_message_reactions CASCADE;
DROP TABLE IF EXISTS agent_conversation_messages CASCADE;
DROP TABLE IF EXISTS agent_conversation_sync CASCADE;
DROP TABLE IF EXISTS agent_programs CASCADE;
DROP TABLE IF EXISTS agent_review_diagnostic_feedback CASCADE;
DROP TABLE IF EXISTS agent_review_diagnostics CASCADE;
DROP TABLE IF EXISTS agent_reviews CASCADE;
DROP TABLE IF EXISTS agent_rule_revisions CASCADE;
DROP TABLE IF EXISTS agent_run_logs CASCADE;
DROP TABLE IF EXISTS agent_runs CASCADE;

-- Now starts the normal pgdump / squash-all output for the agent tables.
CREATE TABLE agent_changeset_revisions (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    changeset_id integer NOT NULL,
    base_oid text NOT NULL,
    head_oid text NOT NULL
);

COMMENT ON TABLE agent_changeset_revisions IS 'Reflects the head/base git revisions of a changeset at a given time. If you push a new commit then a new row is inserted with the new head/base revisions. This table allows us to precisely identify at what snapshot an agent review was run.';

CREATE SEQUENCE agent_changeset_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_changeset_revisions_id_seq OWNED BY agent_changeset_revisions.id;

CREATE TABLE agent_changesets (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    data jsonb,
    repo_id integer GENERATED ALWAYS AS (((data ->> 'repo_id'::text))::integer) STORED,
    pull_number integer GENERATED ALWAYS AS (((data ->> 'pull_number'::text))::integer) STORED,
    github_app_installation_id integer GENERATED ALWAYS AS (((data ->> 'github_app_installation_id'::text))::integer) STORED,
    external_service_type text GENERATED ALWAYS AS ((data ->> 'external_service_type'::text)) STORED,
    external_user_html_url text GENERATED ALWAYS AS ((data ->> 'external_user_html_url'::text)) STORED,
    external_service_id text GENERATED ALWAYS AS ((data ->> 'external_service_id'::text)) STORED NOT NULL,
    external_created_at timestamp with time zone,
    external_updated_at timestamp with time zone,
    is_open boolean GENERATED ALWAYS AS (((data ->> 'state'::text) = 'open'::text)) STORED,
    is_merged boolean GENERATED ALWAYS AS (((data ->> 'merged'::text))::boolean) STORED,
    mergeable_state text GENERATED ALWAYS AS ((data ->> 'mergeable_state'::text)) STORED,
    author_external_username text GENERATED ALWAYS AS (((data -> 'author'::text) ->> 'external_username'::text)) STORED,
    state text GENERATED ALWAYS AS ((data ->> 'state'::text)) STORED,
    draft boolean GENERATED ALWAYS AS (((data ->> 'draft'::text))::boolean) STORED,
    CONSTRAINT check_external_service_type CHECK ((external_service_type = ANY (ARRAY['github'::text, 'gitlab'::text])))
);

COMMENT ON TABLE agent_changesets IS 'A changeset is essentially a GitHub pull request or GitLab merge request. Note that Batch Changes has similar tables to track changesets, but intentionally have a separate table to maximize product velocity and minimize risk of unintended regressions.';

CREATE SEQUENCE agent_changesets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_changesets_id_seq OWNED BY agent_changesets.id;

CREATE TABLE agent_connections (
    id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    agent_id integer NOT NULL,
    type text NOT NULL,
    github_app_id integer,
    webhook_id integer,
    CONSTRAINT agent_connections_type_check CHECK ((type = ANY (ARRAY['github_app'::text, 'github_webhook'::text, 'gitlab_webhook'::text])))
);

CREATE SEQUENCE agent_connections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_connections_id_seq OWNED BY agent_connections.id;

CREATE UNLOGGED TABLE agent_conversation_message_chunks (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    message_id bigint GENERATED ALWAYS AS (((data ->> 'message_id'::text))::integer) STORED NOT NULL,
    data jsonb NOT NULL
);

CREATE UNLOGGED SEQUENCE agent_conversation_message_chunks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_conversation_message_chunks_id_seq OWNED BY agent_conversation_message_chunks.id;

CREATE TABLE agent_conversation_message_reactions (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    data jsonb,
    message_id integer GENERATED ALWAYS AS (((data ->> 'message_id'::text))::integer) STORED NOT NULL,
    user_id integer GENERATED ALWAYS AS (((data ->> 'user_id'::text))::integer) STORED,
    content text GENERATED ALWAYS AS ((data ->> 'content'::text)) STORED NOT NULL,
    external_service_type text GENERATED ALWAYS AS ((data ->> 'external_service_type'::text)) STORED NOT NULL,
    external_api_url text GENERATED ALWAYS AS ((data ->> 'external_api_url'::text)) STORED,
    external_html_url text GENERATED ALWAYS AS ((data ->> 'external_html_url'::text)) STORED,
    external_service_id text GENERATED ALWAYS AS ((data ->> 'external_service_id'::text)) STORED,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    external_creator_id text GENERATED ALWAYS AS ((data ->> 'external_creator_id'::text)) STORED,
    external_creator_username text GENERATED ALWAYS AS ((data ->> 'external_creator_username'::text)) STORED,
    conversation_id integer GENERATED ALWAYS AS (((data ->> 'conversation_id'::text))::integer) STORED NOT NULL
);

CREATE SEQUENCE agent_conversation_message_reactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_conversation_message_reactions_id_seq OWNED BY agent_conversation_message_reactions.id;

CREATE TABLE agent_conversation_messages (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    external_api_url text GENERATED ALWAYS AS ((data ->> 'external_api_url'::text)) STORED,
    external_html_url text GENERATED ALWAYS AS ((data ->> 'external_html_url'::text)) STORED,
    data jsonb,
    conversation_id integer GENERATED ALWAYS AS (((data ->> 'conversation_id'::text))::integer) STORED NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    external_service_id text GENERATED ALWAYS AS ((data ->> 'external_service_id'::text)) STORED,
    external_created_at text GENERATED ALWAYS AS ((data ->> 'external_created_at'::text)) STORED,
    external_updated_at text GENERATED ALWAYS AS ((data ->> 'external_updated_at'::text)) STORED,
    external_creator_id text GENERATED ALWAYS AS ((data ->> 'external_creator_id'::text)) STORED,
    external_creator_username text GENERATED ALWAYS AS ((data ->> 'external_creator_username'::text)) STORED
);

CREATE SEQUENCE agent_conversation_messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_conversation_messages_id_seq OWNED BY agent_conversation_messages.id;

CREATE TABLE agent_conversation_sync (
    id integer NOT NULL,
    external_service_id text NOT NULL,
    last_synced_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE agent_conversation_sync_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_conversation_sync_id_seq OWNED BY agent_conversation_sync.id;

CREATE TABLE agent_conversations (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    data jsonb,
    agent_id integer GENERATED ALWAYS AS (((data ->> 'agent_id'::text))::integer) STORED,
    kind text GENERATED ALWAYS AS ((data ->> 'kind'::text)) STORED NOT NULL,
    external_api_url text GENERATED ALWAYS AS ((data ->> 'external_api_url'::text)) STORED,
    external_html_url text GENERATED ALWAYS AS ((data ->> 'external_html_url'::text)) STORED,
    rule_id text GENERATED ALWAYS AS ((data ->> 'rule_id'::text)) STORED,
    user_id integer GENERATED ALWAYS AS (((data ->> 'user_id'::text))::integer) STORED,
    diagnostic_id integer GENERATED ALWAYS AS (((data ->> 'diagnostic_id'::text))::integer) STORED,
    review_id integer GENERATED ALWAYS AS (((data ->> 'review_id'::text))::integer) STORED,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    external_service_id text GENERATED ALWAYS AS ((data ->> 'external_service_id'::text)) STORED,
    external_created_at text GENERATED ALWAYS AS ((data ->> 'external_created_at'::text)) STORED,
    external_updated_at text GENERATED ALWAYS AS ((data ->> 'external_updated_at'::text)) STORED,
    pull_request_id bigint GENERATED ALWAYS AS (((data ->> 'pull_request_id'::text))::bigint) STORED,
    external_creator_id text GENERATED ALWAYS AS ((data ->> 'external_creator_id'::text)) STORED,
    external_creator_username text GENERATED ALWAYS AS ((data ->> 'external_creator_username'::text)) STORED,
    changeset_id integer GENERATED ALWAYS AS (((data ->> 'changeset_id'::text))::integer) STORED,
    repo_id integer GENERATED ALWAYS AS (((data ->> 'repo_id'::text))::integer) STORED,
    installation_id bigint GENERATED ALWAYS AS (((data ->> 'installation_id'::text))::bigint) STORED
);

CREATE SEQUENCE agent_conversations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_conversations_id_seq OWNED BY agent_conversations.id;

CREATE TABLE agent_programs (
    id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    agent_id integer NOT NULL,
    status text NOT NULL,
    files jsonb NOT NULL,
    CONSTRAINT agent_programs_status_check CHECK ((status = ANY (ARRAY['enabled'::text, 'disabled'::text])))
);

CREATE SEQUENCE agent_programs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_programs_id_seq OWNED BY agent_programs.id;

CREATE TABLE agent_review_diagnostic_feedback (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    data jsonb,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    review_id integer GENERATED ALWAYS AS (((data ->> 'review_id'::text))::integer) STORED,
    diagnostic_id integer GENERATED ALWAYS AS (((data ->> 'diagnostic_id'::text))::integer) STORED,
    user_id integer GENERATED ALWAYS AS ((((data -> 'author'::text) ->> 'user_id'::text))::integer) STORED,
    message_id integer GENERATED ALWAYS AS (((data ->> 'message_id'::text))::integer) STORED,
    reaction_id integer GENERATED ALWAYS AS (((data ->> 'reaction_id'::text))::integer) STORED,
    changeset_id integer GENERATED ALWAYS AS (((data ->> 'changeset_id'::text))::integer) STORED,
    CONSTRAINT check_confusion_label CHECK ((((data ->> 'confusion_label'::text) IS NULL) OR ((data ->> 'confusion_label'::text) = ANY (ARRAY['true-positive'::text, 'false-positive'::text, 'true-negative'::text, 'false-negative'::text])))),
    CONSTRAINT check_helpfulness_label CHECK ((((data ->> 'helpfulness_label'::text) IS NULL) OR ((data ->> 'helpfulness_label'::text) = ANY (ARRAY['strongly-agree'::text, 'agree'::text, 'neutral'::text, 'disagree'::text, 'strongly-disagree'::text]))))
);

CREATE SEQUENCE agent_review_diagnostic_feedback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_review_diagnostic_feedback_id_seq OWNED BY agent_review_diagnostic_feedback.id;

CREATE TABLE agent_review_diagnostics (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    data jsonb,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    review_id integer GENERATED ALWAYS AS (((data ->> 'review_id'::text))::integer) STORED,
    rule_id integer GENERATED ALWAYS AS ((((data -> 'rule'::text) ->> 'rule_id'::text))::integer) STORED,
    rule_revision_id integer GENERATED ALWAYS AS ((((data -> 'rule'::text) ->> 'revision_id'::text))::integer) STORED,
    rule_uri text GENERATED ALWAYS AS (((data -> 'rule'::text) ->> 'uri'::text)) STORED,
    severity text GENERATED ALWAYS AS ((data ->> 'severity'::text)) STORED,
    quality text GENERATED ALWAYS AS ((data ->> 'quality'::text)) STORED
);

CREATE SEQUENCE agent_review_diagnostics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_review_diagnostics_id_seq OWNED BY agent_review_diagnostics.id;

CREATE TABLE agent_reviews (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    data jsonb,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    pull_request_api_url text GENERATED ALWAYS AS ((((data -> 'request'::text) -> 'diff'::text) ->> 'pull_request_api_url'::text)) STORED,
    changeset_id integer GENERATED ALWAYS AS (((((data -> 'request'::text) -> 'diff'::text) ->> 'changeset_id'::text))::integer) STORED,
    changeset_revision_id integer GENERATED ALWAYS AS (((((data -> 'request'::text) -> 'diff'::text) ->> 'changeset_revision_id'::text))::integer) STORED,
    repo_id integer GENERATED ALWAYS AS (((((data -> 'request'::text) -> 'diff'::text) ->> 'repo_id'::text))::integer) STORED
);

CREATE SEQUENCE agent_reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_reviews_id_seq OWNED BY agent_reviews.id;

CREATE TABLE agent_rule_revisions (
    id integer NOT NULL,
    rule_id integer GENERATED ALWAYS AS (((data ->> 'rule_id'::text))::integer) STORED NOT NULL,
    instruction text GENERATED ALWAYS AS ((data ->> 'instruction'::text)) STORED NOT NULL,
    instruction_hash text GENERATED ALWAYS AS (digest((data ->> 'instruction'::text), 'sha256'::text)) STORED NOT NULL,
    title text GENERATED ALWAYS AS ((data ->> 'title'::text)) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    data jsonb NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN agent_rule_revisions.instruction_hash IS 'There is a maximum length for a unique index, so we use a hash of the instructionto enforce uniqueness. This is not a security feature, it is only used to enforce uniqueness';

CREATE SEQUENCE agent_rule_revisions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_rule_revisions_id_seq OWNED BY agent_rule_revisions.id;

CREATE TABLE agent_rules (
    id integer NOT NULL,
    data jsonb NOT NULL,
    uri text GENERATED ALWAYS AS ((data ->> 'uri'::text)) STORED NOT NULL,
    parent_rule_id integer GENERATED ALWAYS AS (((data ->> 'parent_rule_id'::text))::integer) STORED,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    state text GENERATED ALWAYS AS ((data ->> 'state'::text)) STORED,
    impact text GENERATED ALWAYS AS ((data ->> 'impact'::text)) STORED,
    CONSTRAINT agent_rules_state_enum CHECK ((state = 'deleted'::text)),
    CONSTRAINT check_impact CHECK ((impact = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])))
);

CREATE SEQUENCE agent_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_rules_id_seq OWNED BY agent_rules.id;

CREATE UNLOGGED TABLE agent_run_logs (
    id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    run_id integer NOT NULL,
    severity text NOT NULL,
    message text NOT NULL,
    fields jsonb,
    CONSTRAINT agent_run_logs_severity_check CHECK ((severity = ANY (ARRAY['debug'::text, 'info'::text, 'warning'::text, 'error'::text])))
);

COMMENT ON TABLE agent_run_logs IS 'unlogged table to support write-heavy workloads. The logs are not critical data so we''re willing to accept the tradeoff that this data may get lost if the database crashes.';

COMMENT ON COLUMN agent_run_logs.id IS 'intentionally bigserial because just a single run can have a lot of logs';

CREATE UNLOGGED SEQUENCE agent_run_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_run_logs_id_seq OWNED BY agent_run_logs.id;

CREATE TABLE agent_runs (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    agent_id integer,
    status text NOT NULL,
    program_id integer,
    parameters jsonb,
    results jsonb DEFAULT '[]'::jsonb NOT NULL,
    CONSTRAINT agent_runs_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'running'::text, 'completed'::text, 'failed'::text])))
);

COMMENT ON COLUMN agent_runs.agent_id IS 'intentionally not null because it allows us to create a run early in a webhook handler before we have identified an associated agent';

CREATE SEQUENCE agent_runs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agent_runs_id_seq OWNED BY agent_runs.id;

CREATE TABLE agents (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    owner_user_id integer,
    title text NOT NULL,
    description text,
    CONSTRAINT agents_description_length_check CHECK ((length(description) <= 3000)),
    CONSTRAINT agents_title_length_check CHECK (((length(title) > 2) AND (length(title) <= 200)))
);

CREATE SEQUENCE agents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE agents_id_seq OWNED BY agents.id;

ALTER TABLE ONLY agent_changeset_revisions ALTER COLUMN id SET DEFAULT nextval('agent_changeset_revisions_id_seq'::regclass);

ALTER TABLE ONLY agent_changesets ALTER COLUMN id SET DEFAULT nextval('agent_changesets_id_seq'::regclass);

ALTER TABLE ONLY agent_connections ALTER COLUMN id SET DEFAULT nextval('agent_connections_id_seq'::regclass);

ALTER TABLE ONLY agent_conversation_message_chunks ALTER COLUMN id SET DEFAULT nextval('agent_conversation_message_chunks_id_seq'::regclass);

ALTER TABLE ONLY agent_conversation_message_reactions ALTER COLUMN id SET DEFAULT nextval('agent_conversation_message_reactions_id_seq'::regclass);

ALTER TABLE ONLY agent_conversation_messages ALTER COLUMN id SET DEFAULT nextval('agent_conversation_messages_id_seq'::regclass);

ALTER TABLE ONLY agent_conversation_sync ALTER COLUMN id SET DEFAULT nextval('agent_conversation_sync_id_seq'::regclass);

ALTER TABLE ONLY agent_conversations ALTER COLUMN id SET DEFAULT nextval('agent_conversations_id_seq'::regclass);

ALTER TABLE ONLY agent_programs ALTER COLUMN id SET DEFAULT nextval('agent_programs_id_seq'::regclass);

ALTER TABLE ONLY agent_review_diagnostic_feedback ALTER COLUMN id SET DEFAULT nextval('agent_review_diagnostic_feedback_id_seq'::regclass);

ALTER TABLE ONLY agent_review_diagnostics ALTER COLUMN id SET DEFAULT nextval('agent_review_diagnostics_id_seq'::regclass);

ALTER TABLE ONLY agent_reviews ALTER COLUMN id SET DEFAULT nextval('agent_reviews_id_seq'::regclass);

ALTER TABLE ONLY agent_rule_revisions ALTER COLUMN id SET DEFAULT nextval('agent_rule_revisions_id_seq'::regclass);

ALTER TABLE ONLY agent_rules ALTER COLUMN id SET DEFAULT nextval('agent_rules_id_seq'::regclass);

ALTER TABLE ONLY agent_run_logs ALTER COLUMN id SET DEFAULT nextval('agent_run_logs_id_seq'::regclass);

ALTER TABLE ONLY agent_runs ALTER COLUMN id SET DEFAULT nextval('agent_runs_id_seq'::regclass);

ALTER TABLE ONLY agents ALTER COLUMN id SET DEFAULT nextval('agents_id_seq'::regclass);

ALTER TABLE ONLY agent_changeset_revisions
    ADD CONSTRAINT agent_changeset_revisions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_changesets
    ADD CONSTRAINT agent_changesets_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_connections
    ADD CONSTRAINT agent_connections_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_conversation_message_chunks
    ADD CONSTRAINT agent_conversation_message_chunks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_conversation_message_reactions
    ADD CONSTRAINT agent_conversation_message_reactions_external_service_id_key UNIQUE (tenant_id, external_service_id);

ALTER TABLE ONLY agent_conversation_message_reactions
    ADD CONSTRAINT agent_conversation_message_reactions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_conversation_messages
    ADD CONSTRAINT agent_conversation_messages_external_service_id_key UNIQUE (external_service_id, tenant_id);

ALTER TABLE ONLY agent_conversation_messages
    ADD CONSTRAINT agent_conversation_messages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_conversation_sync
    ADD CONSTRAINT agent_conversation_sync_external_service_id_tenant_id_key UNIQUE (external_service_id, tenant_id);

ALTER TABLE ONLY agent_conversation_sync
    ADD CONSTRAINT agent_conversation_sync_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_conversations
    ADD CONSTRAINT agent_conversations_external_service_id_key UNIQUE (external_service_id, tenant_id);

ALTER TABLE ONLY agent_conversations
    ADD CONSTRAINT agent_conversations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_programs
    ADD CONSTRAINT agent_programs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_review_diagnostic_feedback
    ADD CONSTRAINT agent_review_diagnostic_feedback_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_review_diagnostics
    ADD CONSTRAINT agent_review_diagnostics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_reviews
    ADD CONSTRAINT agent_reviews_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_rule_revisions
    ADD CONSTRAINT agent_rule_revisions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_rule_revisions
    ADD CONSTRAINT agent_rule_revisions_tenant_id_rule_id_instruction_hash_key UNIQUE (tenant_id, rule_id, instruction_hash);

ALTER TABLE ONLY agent_rules
    ADD CONSTRAINT agent_rules_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_rules
    ADD CONSTRAINT agent_rules_tenant_id_uri_key UNIQUE (tenant_id, uri);

ALTER TABLE ONLY agent_run_logs
    ADD CONSTRAINT agent_run_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_runs
    ADD CONSTRAINT agent_runs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agents
    ADD CONSTRAINT agents_pkey PRIMARY KEY (id);

ALTER TABLE ONLY agent_changesets
    ADD CONSTRAINT unique_external_service_id UNIQUE (external_service_id, tenant_id);

CREATE INDEX agent_connections_agent_id_idx ON agent_connections USING btree (agent_id);

CREATE INDEX agent_connections_github_app_id_idx ON agent_connections USING btree (github_app_id);

CREATE INDEX agent_connections_tenant_id_idx ON agent_connections USING btree (tenant_id);

CREATE INDEX agent_connections_webhook_id_idx ON agent_connections USING btree (webhook_id);

CREATE INDEX agent_conversation_conversation_id_external_api_url_idx ON agent_conversation_messages USING btree (conversation_id, external_api_url);

CREATE INDEX agent_conversation_message_reactions_external_creator_idx ON agent_conversation_message_reactions USING btree (external_creator_id);

CREATE INDEX agent_conversation_message_reactions_message_id_idx ON agent_conversation_message_reactions USING btree (message_id);

CREATE INDEX agent_conversation_message_reactions_user_id_idx ON agent_conversation_message_reactions USING btree (user_id);

CREATE INDEX agent_conversation_messages_external_creator_idx ON agent_conversation_messages USING btree (external_creator_id);

CREATE INDEX agent_conversation_messages_external_service_idx ON agent_conversation_messages USING btree (external_service_id);

CREATE INDEX agent_conversations_agent_id_idx ON agent_conversations USING btree (agent_id);

CREATE INDEX agent_conversations_changeset_id_idx ON agent_conversations USING btree (changeset_id);

CREATE INDEX agent_conversations_diagnostic_id_idx ON agent_conversations USING btree (diagnostic_id);

CREATE INDEX agent_conversations_external_api_url_idx ON agent_conversations USING btree (external_api_url);

CREATE INDEX agent_conversations_external_creator_idx ON agent_conversations USING btree (external_creator_id);

CREATE INDEX agent_conversations_external_html_url_idx ON agent_conversations USING btree (external_html_url);

CREATE INDEX agent_conversations_external_service_idx ON agent_conversations USING btree (external_service_id);

CREATE INDEX agent_conversations_installation_id_idx ON agent_conversations USING btree (installation_id);

CREATE INDEX agent_conversations_kind_idx ON agent_conversations USING btree (kind);

CREATE INDEX agent_conversations_repo_id_idx ON agent_conversations USING btree (repo_id);

CREATE INDEX agent_conversations_review_id_idx ON agent_conversations USING btree (review_id);

CREATE INDEX agent_conversations_rule_id_idx ON agent_conversations USING btree (rule_id);

CREATE INDEX agent_conversations_user_id_idx ON agent_conversations USING btree (user_id);

CREATE INDEX agent_programs_agent_id_idx ON agent_programs USING btree (agent_id);

CREATE INDEX agent_programs_tenant_id_idx ON agent_programs USING btree (tenant_id);

CREATE INDEX agent_review_diagnostic_feedback_diagnostic_id ON agent_review_diagnostic_feedback USING btree (diagnostic_id);

CREATE INDEX agent_review_diagnostic_feedback_review_id ON agent_review_diagnostic_feedback USING btree (review_id);

CREATE INDEX agent_review_diagnostic_feedback_user_id ON agent_review_diagnostic_feedback USING btree (user_id);

CREATE INDEX agent_review_diagnostics_review_id ON agent_review_diagnostics USING btree (review_id);

CREATE INDEX agent_reviews_changeset_id_idx ON agent_reviews USING btree (changeset_id);

CREATE INDEX agent_reviews_pull_request_api_url ON agent_reviews USING btree (pull_request_api_url);

CREATE INDEX agent_run_logs_run_id_idx ON agent_run_logs USING btree (run_id);

CREATE INDEX agent_runs_agent_id_idx ON agent_runs USING btree (agent_id);

CREATE INDEX agent_runs_updated_at_idx ON agent_runs USING btree (updated_at);

CREATE INDEX agents_tenant_id_idx ON agents USING btree (tenant_id);

CREATE INDEX idx_agent_changeset_branches_changeset_id ON agent_changeset_revisions USING btree (changeset_id);

CREATE INDEX idx_agent_changesets_author_external_username ON agent_changesets USING btree (author_external_username);

CREATE INDEX idx_agent_changesets_draft ON agent_changesets USING btree (draft);

CREATE INDEX idx_agent_changesets_external_created_at ON agent_changesets USING btree (external_created_at);

CREATE INDEX idx_agent_changesets_external_service_type ON agent_changesets USING btree (external_service_type);

CREATE INDEX idx_agent_changesets_external_updated_at ON agent_changesets USING btree (external_updated_at);

CREATE INDEX idx_agent_changesets_external_user_html_url ON agent_changesets USING btree (external_user_html_url);

CREATE INDEX idx_agent_changesets_github_app_installation_id ON agent_changesets USING btree (github_app_installation_id);

CREATE INDEX idx_agent_changesets_is_merged ON agent_changesets USING btree (is_merged);

CREATE INDEX idx_agent_changesets_is_open ON agent_changesets USING btree (is_open);

CREATE INDEX idx_agent_changesets_mergeable_state ON agent_changesets USING btree (mergeable_state);

CREATE INDEX idx_agent_changesets_pull_number ON agent_changesets USING btree (pull_number);

CREATE INDEX idx_agent_changesets_repo_id ON agent_changesets USING btree (repo_id);

CREATE INDEX idx_agent_changesets_state ON agent_changesets USING btree (state);

CREATE INDEX idx_agent_review_diagnostics_created_at ON agent_review_diagnostics USING btree (created_at);

CREATE INDEX idx_agent_review_diagnostics_quality ON agent_review_diagnostics USING btree (quality);

CREATE INDEX idx_agent_review_diagnostics_rule_id ON agent_review_diagnostics USING btree (rule_id);

CREATE INDEX idx_agent_review_diagnostics_severity ON agent_review_diagnostics USING btree (severity);

CREATE INDEX idx_agent_reviews_created_at ON agent_reviews USING btree (created_at);

CREATE INDEX idx_agent_rule_revisions_rule_id ON agent_rule_revisions USING btree (rule_id);

CREATE INDEX idx_agent_rules_impact ON agent_rules USING btree (impact);

CREATE INDEX idx_agent_rules_state ON agent_rules USING btree (state);

CREATE TRIGGER update_agent_changesets_updated_at BEFORE UPDATE ON agent_changesets FOR EACH ROW EXECUTE FUNCTION update_agent_changesets_updated_at();

CREATE TRIGGER update_agent_runs_updated_at BEFORE UPDATE ON agent_runs FOR EACH ROW EXECUTE FUNCTION update_agent_runs_updated_at();

ALTER TABLE ONLY agent_changeset_revisions
    ADD CONSTRAINT agent_changeset_revisions_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES agent_changesets(id);

ALTER TABLE ONLY agent_changesets
    ADD CONSTRAINT agent_changesets_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id);

ALTER TABLE ONLY agent_connections
    ADD CONSTRAINT agent_connections_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_connections
    ADD CONSTRAINT agent_connections_github_app_id_fkey FOREIGN KEY (github_app_id) REFERENCES github_apps(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY agent_connections
    ADD CONSTRAINT agent_connections_webhook_id_fkey FOREIGN KEY (webhook_id) REFERENCES webhooks(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY agent_conversation_message_chunks
    ADD CONSTRAINT agent_conversation_message_chunks_message_id_fkey FOREIGN KEY (message_id) REFERENCES agent_conversation_messages(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversation_message_reactions
    ADD CONSTRAINT agent_conversation_message_reactions_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES agent_conversations(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversation_message_reactions
    ADD CONSTRAINT agent_conversation_message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES agent_conversation_messages(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversation_message_reactions
    ADD CONSTRAINT agent_conversation_message_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversation_messages
    ADD CONSTRAINT agent_conversation_messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES agent_conversations(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversations
    ADD CONSTRAINT agent_conversations_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversations
    ADD CONSTRAINT agent_conversations_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES agent_changesets(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversations
    ADD CONSTRAINT agent_conversations_diagnostic_id_fkey FOREIGN KEY (diagnostic_id) REFERENCES agent_review_diagnostics(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversations
    ADD CONSTRAINT agent_conversations_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversations
    ADD CONSTRAINT agent_conversations_review_id_fkey FOREIGN KEY (review_id) REFERENCES agent_reviews(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_conversations
    ADD CONSTRAINT agent_conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_programs
    ADD CONSTRAINT agent_programs_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostic_feedback
    ADD CONSTRAINT agent_review_diagnostic_feedback_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES agent_changesets(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostic_feedback
    ADD CONSTRAINT agent_review_diagnostic_feedback_diagnostic_id_generated_fkey FOREIGN KEY (diagnostic_id) REFERENCES agent_review_diagnostics(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostic_feedback
    ADD CONSTRAINT agent_review_diagnostic_feedback_message_id_fkey FOREIGN KEY (message_id) REFERENCES agent_conversation_messages(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostic_feedback
    ADD CONSTRAINT agent_review_diagnostic_feedback_reaction_id_fkey FOREIGN KEY (reaction_id) REFERENCES agent_conversation_message_reactions(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostic_feedback
    ADD CONSTRAINT agent_review_diagnostic_feedback_review_id_fkey FOREIGN KEY (review_id) REFERENCES agent_reviews(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostic_feedback
    ADD CONSTRAINT agent_review_diagnostic_feedback_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostics
    ADD CONSTRAINT agent_review_diagnostics_review_id_generated_fkey FOREIGN KEY (review_id) REFERENCES agent_reviews(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostics
    ADD CONSTRAINT agent_review_diagnostics_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES agent_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_review_diagnostics
    ADD CONSTRAINT agent_review_diagnostics_rule_revision_id_fkey FOREIGN KEY (rule_revision_id) REFERENCES agent_rule_revisions(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_reviews
    ADD CONSTRAINT agent_reviews_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES agent_changesets(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_reviews
    ADD CONSTRAINT agent_reviews_changeset_revision_id_fkey FOREIGN KEY (changeset_revision_id) REFERENCES agent_changeset_revisions(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_reviews
    ADD CONSTRAINT agent_reviews_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_rule_revisions
    ADD CONSTRAINT agent_rule_revisions_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES agent_rules(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_rules
    ADD CONSTRAINT agent_rules_parent_rule_id_fkey FOREIGN KEY (parent_rule_id) REFERENCES agent_rules(id);

ALTER TABLE ONLY agent_run_logs
    ADD CONSTRAINT agent_run_logs_run_id_fkey FOREIGN KEY (run_id) REFERENCES agent_runs(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_runs
    ADD CONSTRAINT agent_runs_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE;

ALTER TABLE ONLY agent_runs
    ADD CONSTRAINT agent_runs_program_id_fkey FOREIGN KEY (program_id) REFERENCES agent_programs(id) ON DELETE SET NULL;

ALTER TABLE ONLY agents
    ADD CONSTRAINT agents_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE agent_changeset_revisions ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_changesets ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_connections ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_conversation_message_chunks ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_conversation_message_reactions ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_conversation_messages ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_conversation_sync ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_conversations ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_programs ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_review_diagnostic_feedback ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_review_diagnostics ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_reviews ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_rule_revisions ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_rules ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_run_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE agent_runs ENABLE ROW LEVEL SECURITY;

ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON agent_changeset_revisions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_changesets USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_connections USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_conversation_message_chunks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_conversation_message_reactions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_conversation_messages USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_conversation_sync USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_conversations USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_programs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_review_diagnostic_feedback USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_review_diagnostics USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_reviews USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_rule_revisions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_rules USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_run_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agent_runs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON agents USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
