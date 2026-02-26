-- Fix batch spec library template file patterns from glob-style to proper regex
-- The file: filter uses regex, not glob, so "file:.github/workflows/*.yml" should be
-- "file:^\.github/workflows/.*\.ya?ml$" to correctly match workflow files
--
-- The original template has two separate repositoriesMatchingQuery lines:
--   - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:.github/workflows/*.yml patternType:regexp
--   - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:.github/workflows/*.yaml patternType:regexp
--
-- This replaces them with a single query using proper regex:
--   - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:^\.github/workflows/.*\.ya?ml$ patternType:regexp

UPDATE batch_spec_library_records
SET spec = REPLACE(
    spec,
    '  - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:.github/workflows/*.yml patternType:regexp
  - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:.github/workflows/*.yaml patternType:regexp',
    '  - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:^\.github/workflows/.*\.ya?ml$ patternType:regexp'
),
updated_at = NOW()
WHERE name = 'GitHub Actions: Pin Versions';
