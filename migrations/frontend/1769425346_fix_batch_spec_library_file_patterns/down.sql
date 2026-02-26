-- Revert to the original glob-style file patterns

UPDATE batch_spec_library_records
SET spec = REPLACE(
    spec,
    '  - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:^\.github/workflows/.*\.ya?ml$ patternType:regexp',
    '  - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:.github/workflows/*.yml patternType:regexp
  - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:.github/workflows/*.yaml patternType:regexp'
),
updated_at = NOW()
WHERE name = 'GitHub Actions: Pin Versions';
