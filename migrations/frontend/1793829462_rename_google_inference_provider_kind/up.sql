-- Rename the Google inference provider kind. Older code does not recognize the
-- new value, which is acceptable while the provider is experimental.
UPDATE inference_providers
SET kind = 'gemini-enterprise-agent-platform'
WHERE kind = 'google';
