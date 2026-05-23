ALTER TABLE orgs
    DROP CONSTRAINT IF EXISTS orgs_name_valid_chars,
    ADD CONSTRAINT orgs_name_valid_chars
        CHECK (name ~ '^[a-zA-Z0-9](?:[a-zA-Z0-9]|[-.](?=[a-zA-Z0-9]))*-?$'::citext);
