-- Explicit permissions set for users who did not exist yet were granted from
-- pending permissions with source 'user_sync', so the explicit permissions API
-- could not revoke them and repo-centric syncs deleted them. Permission syncs
-- always record the user's external account, so a user's permission without one
-- can only be explicit.
UPDATE user_repo_permissions
SET source = 'api'
WHERE user_external_account_id IS NULL
    AND user_id IS NOT NULL
    AND source <> 'api';
