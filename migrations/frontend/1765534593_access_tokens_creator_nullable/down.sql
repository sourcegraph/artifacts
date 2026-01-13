-- Revert creator_user_id to NOT NULL and restore original FK constraint.

-- 1) Delete any tokens with NULL creator_user_id
DELETE FROM access_tokens WHERE creator_user_id IS NULL;

-- 2) Drop the new FK constraint
ALTER TABLE access_tokens
    DROP CONSTRAINT IF EXISTS access_tokens_creator_user_id_fkey;

-- 3) Make column NOT NULL again
ALTER TABLE access_tokens
    ALTER COLUMN creator_user_id SET NOT NULL;

-- 4) Recreate the original FK without ON DELETE SET NULL
ALTER TABLE access_tokens
    ADD CONSTRAINT access_tokens_creator_user_id_fkey
    FOREIGN KEY (creator_user_id)
    REFERENCES users(id);
