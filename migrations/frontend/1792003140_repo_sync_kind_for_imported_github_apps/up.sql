-- GitHub Apps added through "Add an existing GitHub App" were saved in the repos
-- domain with the SITE_CREDENTIAL kind. No other path creates that combination:
-- Batch Changes credential apps always use the batches domain. Fix these apps
-- to be repository-sync apps.
UPDATE github_apps
SET kind = 'REPO_SYNC'
WHERE domain = 'repos' AND kind = 'SITE_CREDENTIAL';
