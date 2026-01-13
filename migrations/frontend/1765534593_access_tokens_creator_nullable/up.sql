-- Make creator_user_id nullable so tokens can survive when their creator is deleted.
-- This supports the semantics that tokens belong to the subject user, not the creator.

-- 1) Make column nullable
ALTER TABLE access_tokens
    ALTER COLUMN creator_user_id DROP NOT NULL;

-- 2) Drop the existing FK constraint
ALTER TABLE access_tokens
    DROP CONSTRAINT IF EXISTS access_tokens_creator_user_id_fkey;

-- 3) Recreate FK with ON DELETE SET NULL
ALTER TABLE access_tokens
    ADD CONSTRAINT access_tokens_creator_user_id_fkey
    FOREIGN KEY (creator_user_id)
    REFERENCES users(id)
    ON DELETE SET NULL;
