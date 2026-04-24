-- Fix typo: the constraint used "push-only" but all application code uses "pushed-only"
-- Drop the constraint first so we can update existing rows
ALTER TABLE ONLY changeset_specs
    DROP CONSTRAINT IF EXISTS changeset_specs_published_valid_values;

UPDATE changeset_specs SET published = '"pushed-only"' WHERE published = '"push-only"';

ALTER TABLE ONLY changeset_specs
    ADD CONSTRAINT changeset_specs_published_valid_values
    CHECK (((published = 'true'::text) OR (published = 'false'::text) OR (published = '"draft"'::text) OR (published = '"pushed-only"'::text) OR (published IS NULL)));
