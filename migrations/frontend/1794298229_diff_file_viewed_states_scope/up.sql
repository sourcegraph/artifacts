-- Viewed marks are keyed by an opaque scope instead of the comparison's base and
-- head refs, so that pages whose diff revisions change, like a changeset's head
-- commit after a push, can keep their marks. Existing marks keep matching: the
-- default scope of a comparison is "<base>...<head>".
ALTER TABLE diff_file_viewed_states ADD COLUMN IF NOT EXISTS scope TEXT;

UPDATE diff_file_viewed_states SET scope = base_ref || '...' || head_ref WHERE scope IS NULL;

-- Older versions insert rows without a scope during a rolling deploy. Give them
-- the default scope of their comparison.
CREATE OR REPLACE FUNCTION diff_file_viewed_states_default_scope() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.scope IS NULL THEN
        NEW.scope := NEW.base_ref || '...' || NEW.head_ref;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS diff_file_viewed_states_default_scope ON diff_file_viewed_states;
CREATE TRIGGER diff_file_viewed_states_default_scope
    BEFORE INSERT ON diff_file_viewed_states
    FOR EACH ROW EXECUTE FUNCTION diff_file_viewed_states_default_scope();

ALTER TABLE diff_file_viewed_states DROP CONSTRAINT IF EXISTS diff_file_viewed_states_pkey;
ALTER TABLE diff_file_viewed_states ADD CONSTRAINT diff_file_viewed_states_pkey
    PRIMARY KEY (tenant_id, user_id, repo_id, scope, file_path);

-- Rows of scopes that aren't a comparison have no base and head refs.
ALTER TABLE diff_file_viewed_states ALTER COLUMN base_ref DROP NOT NULL;
ALTER TABLE diff_file_viewed_states ALTER COLUMN head_ref DROP NOT NULL;
