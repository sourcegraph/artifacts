ALTER TABLE agent_reviews ADD COLUMN IF NOT EXISTS changeset_id INTEGER GENERATED ALWAYS AS ((data->'request'->'diff'->>'changeset_id')::integer) STORED REFERENCES agent_changesets(id) ON DELETE CASCADE;
ALTER TABLE agent_reviews ADD COLUMN IF NOT EXISTS changeset_revision_id INTEGER GENERATED ALWAYS AS ((data->'request'->'diff'->>'changeset_revision_id')::integer) STORED REFERENCES agent_changeset_revisions(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS agent_reviews_changeset_id_idx ON agent_reviews (changeset_id);

ALTER TABLE agent_conversations ADD COLUMN IF NOT EXISTS changeset_id INTEGER GENERATED ALWAYS AS ((data->>'changeset_id')::integer) STORED REFERENCES agent_changesets(id) ON DELETE CASCADE;
ALTER TABLE agent_conversations ADD COLUMN IF NOT EXISTS repo_id INTEGER GENERATED ALWAYS AS ((data->>'repo_id')::integer) STORED REFERENCES repo(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS agent_conversations_changeset_id_idx ON agent_conversations (changeset_id);
CREATE INDEX IF NOT EXISTS agent_conversations_repo_id_idx ON agent_conversations (repo_id);
