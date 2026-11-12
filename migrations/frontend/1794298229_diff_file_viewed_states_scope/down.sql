-- Marks of scopes that aren't a comparison can't be keyed by base and head refs.
DELETE FROM diff_file_viewed_states WHERE base_ref IS NULL OR head_ref IS NULL;

ALTER TABLE diff_file_viewed_states DROP CONSTRAINT IF EXISTS diff_file_viewed_states_pkey;
ALTER TABLE diff_file_viewed_states ADD CONSTRAINT diff_file_viewed_states_pkey
    PRIMARY KEY (tenant_id, user_id, repo_id, base_ref, head_ref, file_path);

DROP TRIGGER IF EXISTS diff_file_viewed_states_default_scope ON diff_file_viewed_states;
DROP FUNCTION IF EXISTS diff_file_viewed_states_default_scope();

ALTER TABLE diff_file_viewed_states DROP COLUMN IF EXISTS scope;
