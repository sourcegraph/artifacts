-- Undo the changes made in the up migration

DELETE FROM prompts WHERE name IN ('document-code', 'explain-code', 'generate-unit-tests', 'find-code-smells') AND builtin = 't';
