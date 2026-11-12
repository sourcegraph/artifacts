-- Record the author on user prompts stored before author_user_id existed.
-- Only the owner could send a prompt, and the owner grant history keeps
-- each ownership interval, so the grant covering the prompt's created_at
-- names its author. Wake messages (wake_kind set) have no author. Grants
-- of deleted users have user_id NULL and are skipped, matching the reader.
UPDATE batch_change_agent_thread_entries e
SET payload = e.payload || jsonb_build_object('author_user_id', g.user_id)
FROM batch_change_agent_threads t
JOIN batch_change_agent_access_grants g
  ON g.agent_id = t.agent_id
 AND g.tenant_id = t.tenant_id
 AND g.relation = 'owner'
WHERE e.thread_id = t.id
  AND e.tenant_id = t.tenant_id
  AND e.kind = 'user_message'
  AND NOT e.payload ? 'author_user_id'
  AND e.payload->>'wake_kind' IS NULL
  AND g.user_id IS NOT NULL
  AND g.created_at <= e.created_at
  AND (g.revoked_at IS NULL OR g.revoked_at > e.created_at);
