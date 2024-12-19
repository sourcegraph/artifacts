CREATE TABLE IF NOT EXISTS prompt_tags
(
    id           SERIAL PRIMARY KEY,
    name         TEXT                                                                                    NOT NULL,

    created_by   integer                                                                                 references users (id) ON DELETE SET NULL,
    created_at   timestamp with time zone DEFAULT now()                                                  NOT NULL,
    updated_by   integer                                                                                 references users (id) ON DELETE SET NULL,
    updated_at   timestamp with time zone DEFAULT now()                                                  NOT NULL,
    tenant_id    integer                  DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,

    CONSTRAINT prompt_tags_name_max_length CHECK ((char_length((name)::text) <= 255)),
    CONSTRAINT prompt_tags_name_valid_chars CHECK ((name OPERATOR (~)
                                                      '^[a-zA-Z0-9](?:[a-zA-Z0-9]|[-.](?=[a-zA-Z0-9]))*-?$'::citext)),
    UNIQUE (tenant_id, name)
);

ALTER TABLE prompt_tags
    ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON prompt_tags;
CREATE POLICY tenant_isolation_policy ON prompt_tags AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id =
                                                                                                  (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

CREATE TABLE IF NOT EXISTS prompts_tags_mappings
(
    prompt_id   integer references prompts (id) ON DELETE CASCADE,
    prompt_tag_id integer references prompt_tags (id) ON DELETE CASCADE,

    created_by  integer                                                                                 references users (id) ON DELETE SET NULL,
    created_at  timestamp with time zone DEFAULT now()                                                  NOT NULL,
    tenant_id   integer                  DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,

    PRIMARY KEY (prompt_id, prompt_tag_id, tenant_id)
);

ALTER TABLE prompts_tags_mappings
    ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON prompts_tags_mappings;
CREATE POLICY tenant_isolation_policy ON prompts_tags_mappings AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id =
                                                                                                  (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
