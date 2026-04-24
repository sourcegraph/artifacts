-- Revert: restore the old constraint with "push-only"
ALTER TABLE ONLY changeset_specs
    DROP CONSTRAINT IF EXISTS changeset_specs_published_valid_values;

UPDATE changeset_specs SET published = '"push-only"' WHERE published = '"pushed-only"';

ALTER TABLE ONLY changeset_specs
    ADD CONSTRAINT changeset_specs_published_valid_values
    CHECK (((published = 'true'::text) OR (published = 'false'::text) OR (published = '"draft"'::text) OR (published = '"push-only"'::text) OR (published IS NULL)));
