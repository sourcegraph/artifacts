-- Restore the previous locale-dependent constraints.
ALTER TABLE users
    DROP CONSTRAINT IF EXISTS users_username_valid_chars,
    ADD CONSTRAINT users_username_valid_chars
        CHECK (username ~ '^\w(?:\w|[-.](?=\w))*-?$'::citext);

ALTER TABLE orgs
    DROP CONSTRAINT IF EXISTS orgs_name_valid_chars,
    ADD CONSTRAINT orgs_name_valid_chars
        CHECK (name ~ '^\w(?:\w|[-.](?=\w))*-?$'::citext);
