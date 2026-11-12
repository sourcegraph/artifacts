-- Suppress historical completion bells only for already-settled runs. An idle
-- conversation can still have background work or attention that must settle later.
WITH agent_specs AS (
    SELECT agent_id, materialized_batch_spec_id AS batch_spec_id, tenant_id
    FROM batch_change_agent_spec_drafts
    WHERE materialized_batch_spec_id IS NOT NULL
    UNION
    SELECT bc.agent_id, bs.id AS batch_spec_id, bc.tenant_id
    FROM batch_specs AS bs
    JOIN batch_changes AS bc ON bc.id = bs.batch_change_id AND bc.tenant_id = bs.tenant_id
    WHERE bc.agent_id IS NOT NULL
    UNION
    SELECT agent_id, batch_spec_id, tenant_id
    FROM batch_changes
    WHERE agent_id IS NOT NULL
), settled AS (
    SELECT a.id, a.tenant_id,
        a.stopped_at IS NULL AND EXISTS (
            SELECT 1
            FROM batch_changes AS bc
            JOIN changesets AS c ON c.owned_by_batch_change_id = bc.id AND c.tenant_id = bc.tenant_id
            WHERE bc.agent_id = a.id AND bc.tenant_id = a.tenant_id
              AND CASE WHEN c.computed_state IN ('PROCESSING', 'SCHEDULED', 'RETRYING', 'FAILED')
                  THEN COALESCE(NULLIF(c.external_state, ''), 'UNPUBLISHED')
                  ELSE c.computed_state
              END IN ('DRAFT', 'OPEN')
        ) AS awaiting_merge
    FROM batch_change_agents AS a
    WHERE a.deleted_at IS NULL
      AND NOT EXISTS (
          SELECT 1 FROM batch_change_agent_threads AS t
          WHERE t.agent_id = a.id AND t.tenant_id = a.tenant_id AND t.state = 'processing'
      )
      AND NOT EXISTS (
          SELECT 1
          FROM batch_change_agent_jobs AS j
          JOIN batch_change_agent_threads AS t ON t.id = j.thread_id AND t.tenant_id = j.tenant_id
          WHERE t.agent_id = a.id AND t.tenant_id = a.tenant_id AND j.state = 'processing'
      )
      AND NOT EXISTS (
          SELECT 1
          FROM agent_specs AS specs
          JOIN batch_spec_workspaces AS w ON w.batch_spec_id = specs.batch_spec_id AND w.tenant_id = specs.tenant_id
          JOIN batch_spec_workspace_execution_jobs AS j ON j.batch_spec_workspace_id = w.id AND j.tenant_id = w.tenant_id
          WHERE specs.agent_id = a.id AND specs.tenant_id = a.tenant_id AND j.state IN ('queued', 'processing')
      )
      AND NOT EXISTS (
          SELECT 1
          FROM batch_changes AS bc
          JOIN changesets AS c ON (c.owned_by_batch_change_id = bc.id OR c.batch_change_ids ? bc.id::text)
              AND c.tenant_id = bc.tenant_id
          WHERE bc.agent_id = a.id AND bc.tenant_id = a.tenant_id
            AND c.reconciler_state IN ('queued', 'processing', 'errored', 'scheduled')
      )
      AND NOT EXISTS (
          SELECT 1
          FROM batch_changes AS bc
          JOIN changeset_jobs AS j ON j.batch_change_id = bc.id AND j.tenant_id = bc.tenant_id
          WHERE bc.agent_id = a.id AND bc.tenant_id = a.tenant_id AND j.state IN ('queued', 'processing', 'errored')
      )
      AND NOT EXISTS (
          SELECT 1
          FROM batch_changes AS bc
          JOIN changeset_hook_events AS e ON e.batch_change_id = bc.id AND e.tenant_id = bc.tenant_id
          JOIN changeset_hook_event_jobs AS j ON j.changeset_hook_event_id = e.id AND j.tenant_id = e.tenant_id
          WHERE bc.agent_id = a.id AND bc.tenant_id = a.tenant_id
            AND (j.state = 'processing' OR (e.state = 'pending' AND j.state IN ('queued', 'errored')))
      )
      AND NOT EXISTS (
          SELECT 1 FROM batch_change_agent_wake_jobs AS j
          WHERE j.agent_id = a.id AND j.tenant_id = a.tenant_id AND j.state IN ('queued', 'processing', 'errored')
      )
      AND NOT EXISTS (
          SELECT 1
          FROM batch_change_agent_deepsearch_conversation_mappings AS m
          JOIN deepsearch_questions AS q ON q.conversation_id = m.deepsearch_conversation_id AND q.tenant_id = m.tenant_id
          JOIN deepsearch_question_jobs AS j ON j.question_id = q.id AND j.tenant_id = q.tenant_id
          WHERE m.batch_change_agent_id = a.id AND m.tenant_id = a.tenant_id AND j.state IN ('queued', 'processing', 'errored')
      )
      AND NOT EXISTS (
          SELECT 1 FROM batch_changes AS bc
          JOIN changesets AS c ON c.owned_by_batch_change_id = bc.id AND c.tenant_id = bc.tenant_id
          WHERE bc.agent_id = a.id AND bc.tenant_id = a.tenant_id
            AND a.stopped_at IS NOT NULL AND (
                (a.close_requested_at IS NOT NULL AND c.publication_state = 'PUBLISHED' AND c.external_state IN ('OPEN', 'DRAFT'))
                OR (c.publish_entitlement_window_started_at IS NOT NULL
                    AND c.publication_state = 'UNPUBLISHED' AND COALESCE(c.external_branch, '') = '')
            )
      )
      AND (a.stopped_at IS NOT NULL OR (
          NOT EXISTS (
              SELECT 1 FROM batch_change_agent_threads AS t
              WHERE t.agent_id = a.id AND t.tenant_id = a.tenant_id AND t.state = 'waiting_for_user'
          )
          AND NOT EXISTS (
              SELECT 1
              FROM batch_change_agent_refusals AS r
              JOIN batch_change_agent_thread_entries AS e ON e.id = r.thread_entry_id AND e.tenant_id = r.tenant_id
              JOIN batch_change_agent_threads AS t ON t.id = e.thread_id AND t.tenant_id = e.tenant_id
              WHERE t.agent_id = a.id AND t.tenant_id = a.tenant_id
          )
          AND NOT EXISTS (
              SELECT 1
              FROM batch_change_agent_threads AS t
              JOIN LATERAL (
                  SELECT e.id, e.sequence
                  FROM batch_change_agent_thread_entries AS e
                  WHERE e.thread_id = t.id AND e.tenant_id = t.tenant_id AND e.kind = 'user_message'
                  ORDER BY e.sequence DESC, e.id DESC LIMIT 1
              ) AS message ON TRUE
              JOIN LATERAL (
                  SELECT e.kind, e.payload
                  FROM batch_change_agent_thread_entries AS e
                  WHERE e.thread_id = t.id AND e.tenant_id = t.tenant_id
                    AND e.sequence > message.sequence AND e.kind <> 'compaction'
                  ORDER BY e.sequence DESC, e.id DESC LIMIT 1
              ) AS tail ON TRUE
              WHERE t.agent_id = a.id AND t.tenant_id = a.tenant_id
                AND NOT COALESCE(t.active_entry_id = message.id AND t.state <> 'idle', false)
                AND tail.kind = 'error' AND tail.payload->>'status' = 'failed'
          )
          AND NOT EXISTS (
              SELECT 1
              FROM batch_spec_workspaces AS w
              JOIN LATERAL (
                  SELECT j.state
                  FROM batch_spec_workspace_execution_jobs AS j
                  WHERE j.batch_spec_workspace_id = w.id AND j.tenant_id = w.tenant_id
                  ORDER BY j.id DESC LIMIT 1
              ) AS job ON TRUE
              WHERE w.tenant_id = a.tenant_id AND NOT w.skipped AND NOT w.cached_result_found AND job.state = 'failed'
                AND w.batch_spec_id = (
                    SELECT d.materialized_batch_spec_id
                    FROM batch_change_agent_spec_drafts AS d
                    WHERE d.agent_id = a.id AND d.tenant_id = a.tenant_id
                      AND d.status = 'materialized' AND d.materialized_batch_spec_id IS NOT NULL
                    ORDER BY d.version DESC, d.id DESC LIMIT 1
                )
          )
          AND NOT EXISTS (
              SELECT 1
              FROM batch_changes AS bc
              JOIN changesets AS c ON c.owned_by_batch_change_id = bc.id AND c.tenant_id = bc.tenant_id
              WHERE bc.agent_id = a.id AND bc.tenant_id = a.tenant_id
                AND COALESCE(NULLIF(c.failure_message, ''), (
                    SELECT j.failure_message FROM changeset_jobs AS j
                    WHERE j.changeset_id = c.id AND j.tenant_id = c.tenant_id
                    ORDER BY j.id DESC LIMIT 1
                ), '') <> ''
          )
      ))
)
UPDATE batch_change_agents AS a
SET notified_awaiting_merge_at = CASE WHEN settled.awaiting_merge
        THEN COALESCE(a.notified_awaiting_merge_at, NOW()) ELSE a.notified_awaiting_merge_at END,
    notified_done_at = CASE WHEN NOT settled.awaiting_merge
        THEN COALESCE(a.notified_done_at, NOW()) ELSE a.notified_done_at END,
    -- Keep the normal observation overlap for activity committed during migration.
    notification_observed_at = COALESCE(a.notification_observed_at, NOW() - INTERVAL '3 minutes')
FROM settled
WHERE a.id = settled.id AND a.tenant_id = settled.tenant_id;
