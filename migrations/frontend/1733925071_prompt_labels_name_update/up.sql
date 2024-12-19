ALTER TABLE prompt_tags
DROP CONSTRAINT prompt_tags_name_valid_chars;

ALTER TABLE prompt_tags
ADD CONSTRAINT prompt_tags_name_valid_chars
CHECK ((name OPERATOR (~) '^[a-zA-Z0-9](?:[a-zA-Z0-9]|[-._\s](?=[a-zA-Z0-9]))*-?$'::citext));
