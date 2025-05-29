ALTER TABLE ONLY changeset_specs
    DROP CONSTRAINT IF EXISTS changeset_specs_published_valid_values,
    ADD CONSTRAINT changeset_specs_published_valid_values 
    CHECK (((published = 'true'::text) OR (published = 'false'::text) OR (published = '"draft"'::text) OR (published IS NULL)));

