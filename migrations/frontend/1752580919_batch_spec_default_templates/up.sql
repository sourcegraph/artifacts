-- Insert Amp batch spec library record
INSERT INTO batch_spec_library_records (name, spec, labels, tenant_id)
SELECT
    'Amp free form prompt' as name,
    'version: 2
name: amp-batch-changes-template
description: Use Sourcegraph''s Amp to make code changes for you through Batch Changes. You must configure the executor secret AMP_API_KEY before running this.

on:
  - repositoriesMatchingQuery: {{ variables.REPOSITORY }}
steps:
  - run: |
      apk add --no-cache nodejs npm git ripgrep
      npm install -g @sourcegraph/amp

      # Create temporary settings.json file
      cat > settings.json << ''SETTINGS_EOF''
      {
          "amp.url": "https://ampcode.com/",
          "amp.debug.usage.enabled": true,
          "amp.commands.allowlist": [
              "*"
          ],
          "amp.connections.disable": [
              "1002"
          ],
          "git.autofetch": true,
          "amp.todos.enabled": true,
          "amp.experimental.connections": true,
          "amp.tab.autoImport.enabled": true
      }
      SETTINGS_EOF

      amp --no-color --no-notifications --settings-file ./settings.json <<EOF
      {{ variables.PROMPT }}
      EOF

      rm settings.json
    container: alpine:3
    env:
    - AMP_API_KEY
changesetTemplate:
  title: "{{ variables.PR_TITLE }}"
  body: "{{ variables.PR_DESCRIPTION }}

This PR has been generated with Amp."

  branch: {{ variables.BRANCH_NAME }}

  commit:
    message: "{{ variables.PR_TITLE }}"
' as spec,
    '{"featured"}'::text[] as labels,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Insert variables for Amp batch spec library record
INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'REPOSITORY' as name,
    'Repository' as display_name,
    '^[a-zA-Z0-9][a-zA-Z0-9.\-\/]*$' as regex_rule,
    'The name of the repository, e.g. github.com/your-org/your-repository' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Amp free form prompt'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'PROMPT' as name,
    'Prompt' as display_name,
    '^[\s\S]+$' as regex_rule,
    'The prompt for Amp.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Amp free form prompt'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'PR_TITLE' as name,
    'Pull Request Title' as display_name,
    '^[\s\S]+$' as regex_rule,
    'The title for the commit and pull request.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Amp free form prompt'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'PR_DESCRIPTION' as name,
    'Pull Request Description' as display_name,
    '^[\s\S]+$' as regex_rule,
    'The description for the pull request.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Amp free form prompt'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'BRANCH_NAME' as name,
    'Target Branch Name' as display_name,
    '^[a-z][a-z0-9\-\/]*$' as regex_rule,
    'The branch name to use for the pull request.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Amp free form prompt'
ON CONFLICT DO NOTHING;

-- Insert Terraform Infrastructure Tags batch spec library record
INSERT INTO batch_spec_library_records (name, spec, labels, tenant_id)
SELECT
    'Terraform Infrastructure Tags' as name,
    'name: add-terraform-infra-tags
description: |
  Add tags to Terraform locals.tf files, such as environment, region, and owner.

on:
  - repositoriesMatchingQuery: file:locals.tf$ lang:HCL tag not {{variables.tagName}}

steps:
  - run: |
      comby -in-place -config /tmp/patterns.toml;
    container: comby/comby
    files:
      /tmp/patterns.toml: |
        [pattern]
        match=''''''locals {
            name = :[name]
            default_tags = {:[block]
            }
        }''''''

        rewrite=''''''locals {
            name = :[name]
            default_tags = {:[block]
            {{variables.tagName}} = "{{variables.tagValue}}"
            }
        }''''''
  - run: terraform fmt
    container: hashicorp/terraform:latest

changesetTemplate:
  title: Add {{variables.tagName}} tag to Terraform infrastructure
  body: |
    This batch change adds the {{variables.tagName}} tag with value "{{variables.tagValue}}" to Terraform locals.tf files.

    This helps with:
    - Resource organization and billing
    - Compliance and governance
    - Infrastructure management
  branch: batches/add-{{variables.tagName}}-tag
  commit:
    message: Add {{variables.tagName}} tag to Terraform infrastructure
' as spec,
    '{}'::text[] as labels,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Insert variables for Terraform Infrastructure Tags
INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'tagName' as name,
    null as display_name,
    '^[A-Za-z][A-Za-z0-9_-]*$' as regex_rule,
    'The name of the tag to add (e.g., ''Environment'', ''Team'', ''CostCenter'')' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Terraform Infrastructure Tags'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'tagValue' as name,
    null as display_name,
    '^[A-Za-z0-9][A-Za-z0-9_.-]*$' as regex_rule,
    'The value for the tag (e.g., ''production'', ''engineering'', ''shared-services'')' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Terraform Infrastructure Tags'
ON CONFLICT DO NOTHING;

-- Insert GitHub Actions: Pin Versions batch spec library record
INSERT INTO batch_spec_library_records (name, spec, labels, tenant_id)
SELECT
    'GitHub Actions: Pin Versions' as name,
    'name: github-actions-pin-version
description: Pin a GitHub Action from an old version to a new version.

on:
  - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:.github/workflows/*.yml patternType:regexp
  - repositoriesMatchingQuery: {{ variables.actionName }}@{{ variables.oldVersion }} file:.github/workflows/*.yaml patternType:regexp

steps:
  - run: |
      for file in "${{ join repository.search_result_paths " " }}"; do
        sed -i ''s|uses: {{ variables.actionName }}@{{ variables.oldVersion }}|uses: {{ variables.actionName }}@{{ variables.newVersion }}|g'' "${file}"
      done
    container: alpine:3

changesetTemplate:
  title: ''Pin {{ variables.actionName }} from {{ variables.oldVersion }} to {{ variables.newVersion }}''
  body: |
    This change pins the GitHub Action {{ variables.actionName }} from {{ variables.oldVersion }} to {{ variables.newVersion }} for security and reproducibility.

    **What Changed:**
    - {{ variables.actionName }}@{{ variables.oldVersion }} → {{ variables.actionName }}@{{ variables.newVersion }}
  branch: pin-github-actions-{{ variables.actionName }}
  commit:
    message: ''Pin {{ variables.actionName }} from {{ variables.oldVersion }} to {{ variables.newVersion }}''
' as spec,
    '{"featured"}'::text[] as labels,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Insert variables for GitHub Actions: Pin Versions
INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'actionName' as name,
    'Action Name' as display_name,
    '^[a-zA-Z0-9_\-]+\/[a-zA-Z0-9_\-]+$' as regex_rule,
    'GitHub Action name to pin (e.g., ''actions/checkout'', ''actions/setup-node'')' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'GitHub Actions: Pin Versions'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'newVersion' as name,
    'New Version' as display_name,
    '^[a-zA-Z0-9][a-zA-Z0-9._\-]*$' as regex_rule,
    'New commit hash or version to pin to (e.g., ''sha12345'')' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'GitHub Actions: Pin Versions'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'oldVersion' as name,
    'Old Version' as display_name,
    '^[a-zA-Z0-9][a-zA-Z0-9._\-]*$' as regex_rule,
    'Current version to replace (e.g., ''v3'', ''v4.1.0'', ''main'')' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'GitHub Actions: Pin Versions'
ON CONFLICT DO NOTHING;

-- Insert Ask Amp to fix CVE-2025-29927 batch spec library record
INSERT INTO batch_spec_library_records (name, spec, labels, tenant_id)
SELECT
    'Ask Amp to fix CVE-2025-29927' as name,
    'version: 2
name: amp-fix-CVE-2025-29927
description: Migrate all legacy versions of nextjs to 15.2.3. You must configure the executor secret AMP_API_KEY before running this.

# Resolve critical Ask Amp to fix CVE-2025-29927 to upgrade all nextjs versions to 15.2.3 https://github.com/vercel/next.js/security/advisories/GHSA-f82v-jwr5-mffw

on:
  - repositoriesMatchingQuery: context:global file:package.json "next":\s*"((0|1[0-4]|[1-9])\.\d+\.\d+|15\.(0|1)\.\d+|15\.2\.[0-2])" patternType:regexp
steps:
  - run: |
      apk add --no-cache nodejs npm git ripgrep
      npm install -g @next/codemod
      npm install -g @sourcegraph/amp
      amp --no-color --no-notifications <<EOF
      - Migrate this project incrementally to next.js 15.2.3 and make any required code changes
      - First read which version of next.js you are using from the "next" package from the package.json file
      - Get instructions for the next upgrade here  https://nextjs.org/docs/pages/guides/upgrading/version-13 as an example, and then when you have finished 13 repeat with https://nextjs.org/docs/pages/guides/upgrading/version-14
      - Please recursively update the versions until you are on 15.2.3
      - Be sure to make any code changes taht a required you can alos use https://nextjs.org/docs/pages/guides/upgrading/codemods for guidance.
      - Generate a PROGRESS.md file:
        - List completed tasks
        - List blocked or manual steps under a "BLOCKED" section
      - Provide detailed explanations of what is changing and why.
      - If there are breaking changes such as node.js version upgrade, please make those upgrades also
      EOF
    container: alpine:3
    env:
      - AMP_API_KEY

changesetTemplate:
  title: Migrate all legacy versions of nextjs to 15.2.3
  body: Migrate all legacy versions of nextjs to 15.2.3

  branch: {{ variables.BRANCH_NAME }}

  commit:
    message: Migrate all legacy versions of nextjs to 15.2.3
' as spec,
    '{}'::text[] as labels,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Insert variables for Ask Amp to fix CVE-2025-29927
INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'BRANCH_NAME' as name,
    'Branch Name' as display_name,
    '^[a-z][a-z0-9\-\/]*$' as regex_rule,
    'The branch name for the migration.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Ask Amp to fix CVE-2025-29927'
ON CONFLICT DO NOTHING;

-- Insert Hello World batch spec library record
INSERT INTO batch_spec_library_records (name, spec, labels, tenant_id)
SELECT
    'Hello World' as name,
    'version: 2
name: hello-world-template
description: Add a variable text to READMEs.

on:
  - repositoriesMatchingQuery: file:README.md count:10

steps:
  - run: IFS=$''\n''; echo {{ variables.TEXT }} | tee -a $(find -name README.md)
    container: ubuntu:18.04

changesetTemplate:
  title: Add {{ variables.TEXT }} to READMEs
  body: My first batch change!
  commit:
    message: Append {{ variables.TEXT }} to all README.md files
  branch: ${{ batch_change.name }}
' as spec,
    '{}'::text[] as labels,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Insert variables for Hello World
INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'TEXT' as name,
    null as display_name,
    '^[\s\S]+$' as regex_rule,
    'The text to be added to READMEs.' as description,
    false as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Hello World'
ON CONFLICT DO NOTHING;

-- Insert Text replacement batch spec library record
INSERT INTO batch_spec_library_records (name, spec, labels, tenant_id)
SELECT
    'Text replacement' as name,
    'version: 2
name: text-replacement
description: Replace text using regex patterns

on:
  - repositoriesMatchingQuery: {{ variables.QUERY }}

steps:
  - run: |
      while read -r file
      do
        sed -i ''s/{{ variables.FIND_PATTERN }}/{{ variables.REPLACE_PATTERN }}/g;'' "${file}"
      done < <(echo ''${{ join repository.search_result_paths "\n" }}'')
    container: alpine:3

changesetTemplate:
  title: Replace ''{{ variables.FIND_PATTERN }}'' with ''{{ variables.REPLACE_PATTERN }}''
  body: This batch change replaces all occurrences of ''{{ variables.FIND_PATTERN }}'' with ''{{ variables.REPLACE_PATTERN }}'' in the matched files.
  branch: {{ variables.BRANCH_NAME }}
  commit:
    message: Replace ''{{ variables.FIND_PATTERN }}'' with ''{{ variables.REPLACE_PATTERN }}''
' as spec,
    '{"featured"}'::text[] as labels,
    tenants.id AS tenant_id
FROM tenants
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Insert variables for Text replacement
INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'BRANCH_NAME' as name,
    'Branch Name' as display_name,
    '^[\s\S]+$' as regex_rule,
    'The branch name for the changes.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Text replacement'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'FIND_PATTERN' as name,
    'Find Pattern' as display_name,
    '^[\s\S]+$' as regex_rule,
    'The regex pattern to find in files.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Text replacement'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'QUERY' as name,
    'Repository Search Query' as display_name,
    '^[\s\S]+$' as regex_rule,
    'The search query to find repositories.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Text replacement'
ON CONFLICT DO NOTHING;

INSERT INTO batch_spec_library_variables (batch_spec_library_record_id, name, display_name, regex_rule, description, mandatory, level, tenant_id)
SELECT
    bslr.id as batch_spec_library_record_id,
    'REPLACE_PATTERN' as name,
    'Replace Pattern' as display_name,
    '^[\s\S]+$' as regex_rule,
    'The replacement pattern.' as description,
    true as mandatory,
    'error' as level,
    tenants.id as tenant_id
FROM tenants
JOIN batch_spec_library_records bslr ON bslr.tenant_id = tenants.id AND bslr.name = 'Text replacement'
ON CONFLICT DO NOTHING;
