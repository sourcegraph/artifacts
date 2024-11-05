CREATE TABLE IF NOT EXISTS user_public_repos (
    user_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    repo_uri text NOT NULL,
    repo_id integer NOT NULL REFERENCES repo(id) ON DELETE CASCADE,
    tenant_id integer DEFAULT 1 REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (user_id, repo_id)
);
