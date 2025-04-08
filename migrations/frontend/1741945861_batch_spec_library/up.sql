CREATE TABLE IF NOT EXISTS batch_spec_library_records
(
    id                 BIGSERIAL PRIMARY KEY,
    name               text                                      NOT NULL,
    spec               text                                      NOT NULL,
    created_at         timestamp without time zone DEFAULT now() NOT NULL,
    updated_at         timestamp with time zone    DEFAULT now() NOT NULL,
    created_by_user_id integer,
    tenant_id          INTEGER                                   NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

CREATE UNIQUE INDEX IF NOT EXISTS batch_spec_library_records_name_idx ON batch_spec_library_records (tenant_id, name);

ALTER TABLE batch_spec_library_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_spec_library_records;
CREATE POLICY tenant_isolation_policy ON batch_spec_library_records AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::INTEGER AS current_tenant));

INSERT INTO batch_spec_library_records (name, spec, tenant_id)
SELECT
    'comby' as name,
    'version: 2
name: sprintf-to-itoa
description: |
  This batch change uses [Comby](https://comby.dev) to replace `fmt.Sprintf` calls
  in Go code with the equivalent but clearer `strconv.Iota` call.

# Find all repositories that contain the `fmt.Sprintf` statement using regular expression search
on:
  - repositoriesMatchingQuery: lang:go fmt.Sprintf\("%d", \w+\) patterntype:regexp

steps:
  # Run Comby (https://comby.dev) to replace the Go statements...
  - run: comby -in-place ''fmt.Sprintf("%d", :[v])'' ''strconv.Itoa(:[v])'' .go -matcher .go -exclude-dir .,vendor
    container: comby/comby
  # ... and then run goimports to make sure `strconv` is imported.
  - run: goimports -w $(find . -type f -name ''*.go'' -not -path "./vendor/*")
    container: unibeautify/goimports

# Describe the changeset (e.g., GitHub pull request) you want for each repository.
changesetTemplate:
  title: Replace equivalent fmt.Sprintf calls with strconv.Itoa
  body: This batch change replaces `fmt.Sprintf("%d", integer)` calls with semantically equivalent `strconv.Itoa` calls
  branch: batches/sprintf-to-itoa # Push the commit to this branch.
  commit:
    message: Replacing fmt.Sprintf with strconv.Iota
' as spec,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_records (name, spec, tenant_id)
SELECT
    'go-imports' as name,
    'version: 2
name: update-log15-import
description: This batch change updates Go import paths for the `log15` package from `gopkg.in/inconshreveable/log15.v2` to `github.com/inconshreveable/log15` using [Comby](https://comby.dev/)

# Find all repositories that contain the import we want to change.
on:
  - repositoriesMatchingQuery: lang:go gopkg.in/inconshreveable/log15.v2

# In each repository
steps:
  # we first replace the import when it''s part of a multi-package import statement
  - run: comby -in-place ''import (:[before]"gopkg.in/inconshreveable/log15.v2":[after])'' ''import (:[before]"github.com/inconshreveable/log15":[after])'' .go -matcher .go -exclude-dir .,vendor
    container: comby/comby
  # ... and when it''s a single import line.
  - run: comby -in-place ''import "gopkg.in/inconshreveable/log15.v2"'' ''import "github.com/inconshreveable/log15"'' .go -matcher .go -exclude-dir .,vendor
    container: comby/comby

# Describe the changeset (e.g., GitHub pull request) you want for each repository.
changesetTemplate:
  title: Update import path for log15 package to use GitHub
  body: Updates Go import paths for the `log15` package from `gopkg.in/inconshreveable/log15.v2` to `github.com/inconshreveable/log15` using [Comby](https://comby.dev/)
  branch: batches/update-log15-import # Push the commit to this branch.
  commit:
    message: Fix import path for log15 package
' as spec,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_records (name, spec, tenant_id)
SELECT
    'hello-world' as name,
    'version: 2
name: hello-world
description: Add Hello World to READMEs

# Find the first 100 search results for README files.
# This could yield less than 100 repos/workspaces if some repos contain multiple READMEs.
on:
  - repositoriesMatchingQuery: file:README.md count:100

# In each repository, run this command. Each repository''s resulting diff is captured.
steps:
  - run: IFS=$''\n''; echo Hello World | tee -a $(find -name README.md)
    container: ubuntu:18.04

# Describe the changeset (e.g., GitHub pull request) you want for each repository.
changesetTemplate:
  title: Hello World
  body: My first batch change!
  commit:
    message: Append Hello World to all README.md files
  # Optional: Push the commit to a branch named after this batch change by default.
  branch: ${{ batch_change.name }}
' as spec,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_records (name, spec, tenant_id)
SELECT
    'many-comby' as name,
    'version: 2
name: many-comby
description: |
  Apply many comby match patterns
on:
  - repositoriesMatchingQuery: <<CHANGE_ME>>

# comby can take a configuration file listing patterns to apply
# https://comby.dev/docs/configuration
steps:
  - run: |
      comby -in-place -config  /tmp/patterns.toml -exclude-dir .,vendor;
    container: comby/comby
    # files to mount on the container can be directly included in the spec file
    # for other options, see https://sourcegraph.com/docs/batch_changes/references/batch_spec_yaml_reference#stepsmount
    files:
      /tmp/patterns.toml: |
        [my-first-pattern]
        match="Array.prototype.slice.call(:[arguments]);"
        rewrite="Array.from(:[arguments])"

        [my-second-pattern-multiline]
        match=''''''
        function :[[fn]](:[1], :[2]) {
          :[body]
        };''''''

        rewrite=''''''
        function :[[fn]](:[2], :[1]) {
          :[body]
        };''''''


# Describe the changeset (e.g., GitHub pull request) you want for each repository.
changesetTemplate:
  title: Apply many comby match patterns
  body: Apply many comby match patterns
  branch: batches/many-comby
  commit:
    message: many comby
' as spec,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_records (name, spec, tenant_id)
SELECT
    'minimal' as name,
    'version: 2
name: my-batch-change
# Add your own description, query, steps, changesetTemplate, etc.
' as spec,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_records (name, spec, tenant_id)
SELECT
    'monorepo-dynamic' as name,
    'version: 2
name: monorepo-dynamic
description: |
  Create one changeset per workspace in the sourcegraph frontend monorepo
  Workspaces are set where some file is present, eg. package.json in this example
on:
  - repository: github.com/sourcegraph/sourcegraph


# Each time a package.json is found at a path, batch change will treat it as a workspace
workspaces:
  - rootAtLocationOf: package.json
    in: "*"

# Batch change steps will run in each workspace
steps:
  - run: |
      if [[ $(pwd) = "/work" ]]; then
        echo "This is the root workspace, skipping"
      else
        echo "I''m running in $PWD" > hello-world.md
      fi
    container: alpine:3

changesetTemplate:
  title: Run in each workspace of a monorepo
  body: |
    Run in each workspace of a monorepo
# Each branch needs to be unique, so we''re using templating to define them
# https://sourcegraph.com/docs/batch_changes/references/batch_spec_templating
  branch: batch-changes/monorepo/${{ replace steps.path "/" "-" }}
  commit:
    message: opening several changesets in a monorepo
' as spec,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_records (name, spec, tenant_id)
SELECT
    'sed' as name,
    'version: 2
name: apply-regex-sed
description: Apply a regex using sed

on:
  - repositoriesMatchingQuery: <<CHANGE_ME>>

steps:
  # In each repo, iterate over search results files using templating
  # https://sourcegraph.com/docs/batch_changes/references/batch_spec_templating
  - run: |
      while read -r file
      do
        sed -i ''s/replace-me/by-me/g;'' "${file}"
      done < <(echo ''${{ join repository.search_result_paths "\n" }}'')
    container: alpine:3

changesetTemplate:
  title: Apply a regex
  body: Apply a regex using sed
  branch: batch-changes/regex
  commit:
    message: batch changes -  apply regex
' as spec,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT DO NOTHING;
