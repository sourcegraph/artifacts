-- Notifications keyed code_host_token_expired:<external service id> are left
-- over from before the key was renamed to external_service_sync_failed.
-- Nothing clears the legacy key, so these rows stay active forever.
DELETE FROM notifications WHERE key LIKE 'code_host_token_expired:%';
