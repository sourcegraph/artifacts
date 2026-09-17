DO $migration$
BEGIN
    IF to_regclass('batch_change_agent_messages') IS NULL THEN
        RETURN;
    END IF;

ALTER TABLE batch_change_agent_threads
    ADD COLUMN IF NOT EXISTS state TEXT NOT NULL DEFAULT 'idle',
    ADD COLUMN IF NOT EXISTS active_message_id INTEGER REFERENCES batch_change_agent_messages(id) ON DELETE SET NULL;

ALTER TABLE batch_change_agent_threads
    DROP CONSTRAINT IF EXISTS batch_change_agent_threads_state_check;
ALTER TABLE batch_change_agent_threads
    ADD CONSTRAINT batch_change_agent_threads_state_check
    CHECK (state IN ('idle', 'processing', 'waiting_for_user'));

COMMENT ON COLUMN batch_change_agent_threads.active_message_id IS
    'Internal execution identity for the active worker run. Transcript ownership lives on batch_change_agent_thread_entries.';

CREATE TABLE IF NOT EXISTS batch_change_agent_thread_entries (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    thread_id INTEGER NOT NULL REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,
    sequence BIGINT NOT NULL,
    -- message_id is an internal run correlation only. Entries, rather than
    -- messages, own the visible and replayable transcript.
    message_id INTEGER REFERENCES batch_change_agent_messages(id) ON DELETE SET NULL,
    -- Groups the ordered parts produced by one provider call. User messages,
    -- externally supplied tool results, and compactions each get their own group.
    turn_id BIGINT NOT NULL,
    kind TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    compacted_through_entry_id BIGINT REFERENCES batch_change_agent_thread_entries(id) ON DELETE RESTRICT,
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_thread_entries_sequence_check CHECK (sequence > 0),
    CONSTRAINT batch_change_agent_thread_entries_turn_id_check CHECK (turn_id > 0),
    CONSTRAINT batch_change_agent_thread_entries_kind_check CHECK (
        kind IN ('user_message', 'thinking', 'assistant_text', 'tool_call', 'tool_result', 'compaction', 'error')
    ),
    CONSTRAINT batch_change_agent_thread_entries_compaction_cutoff_check CHECK (
        (kind = 'compaction' AND compacted_through_entry_id IS NOT NULL)
        OR (kind <> 'compaction' AND compacted_through_entry_id IS NULL)
    )
);

COMMENT ON TABLE batch_change_agent_thread_entries IS
    'Append-only chronological transcript for a batch change agent thread. Provider content parts retain their original relative order.';
COMMENT ON COLUMN batch_change_agent_thread_entries.compacted_through_entry_id IS
    'For compaction entries, the last transcript entry represented by the summary. Replay uses the latest compaction plus entries after this cutoff.';

ALTER TABLE batch_change_agent_thread_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_thread_entries;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_thread_entries AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_thread_entries_thread_sequence_idx
    ON batch_change_agent_thread_entries (tenant_id, thread_id, sequence);
CREATE INDEX IF NOT EXISTS batch_change_agent_thread_entries_thread_id_idx
    ON batch_change_agent_thread_entries (thread_id, sequence, id, tenant_id);
CREATE INDEX IF NOT EXISTS batch_change_agent_thread_entries_message_id_idx
    ON batch_change_agent_thread_entries (message_id, tenant_id)
    WHERE message_id IS NOT NULL;

-- Backfill the legacy Message -> Turn hierarchy into its only recoverable
-- ordering. Historical rows did not retain provider interleaving, so their
-- canonical order is thinking, assistant text, tool calls, then tool results.
WITH candidates AS (
    SELECT
        m.tenant_id,
        m.thread_id,
        m.id AS message_id,
        t.id AS turn_id,
        m.sequence AS message_sequence,
        t.sequence AS turn_sequence,
        t.created_at,
        100000::BIGINT AS part_order,
        'thinking'::TEXT AS kind,
        jsonb_strip_nulls(jsonb_build_object('text', t.thinking, 'signature', t.thinking_signature)) AS payload,
        t.stats
    FROM batch_change_agent_turns t
    JOIN batch_change_agent_messages m ON m.id = t.message_id
    WHERE t.thinking IS NOT NULL OR t.thinking_signature IS NOT NULL

    UNION ALL

    SELECT
        m.tenant_id,
        m.thread_id,
        m.id,
        t.id,
        m.sequence,
        t.sequence,
        t.created_at,
        200000,
        CASE WHEN t.role = 'user' THEN 'user_message' ELSE 'assistant_text' END,
        jsonb_strip_nulls(jsonb_build_object(
            'text', t.reasoning,
            'attachments', CASE WHEN t.role = 'user' THEN t.content ELSE NULL END,
            'wake_kind', CASE WHEN t.role = 'user' THEN m.wake_kind ELSE NULL END
        )),
        t.stats
    FROM batch_change_agent_turns t
    JOIN batch_change_agent_messages m ON m.id = t.message_id
    -- Legacy user turns that only carry tool results (ask_user answers, approval
    -- decisions) have empty reasoning and JSON null content, so they must not
    -- produce an empty user_message entry. Only a non-empty attachment array
    -- counts as user content.
    WHERE t.reasoning <> ''
       OR (t.role = 'user' AND jsonb_typeof(t.content) = 'array' AND t.content <> '[]'::jsonb)

    UNION ALL

    SELECT
        m.tenant_id,
        m.thread_id,
        m.id,
        t.id,
        m.sequence,
        t.sequence,
        t.created_at,
        300000 + call.ordinality,
        'tool_call',
        CASE
            WHEN COALESCE(call.value->>'type', '') = ''
                THEN jsonb_set(call.value, '{type}', '"function"'::jsonb)
            ELSE call.value
        END,
        t.stats
    FROM batch_change_agent_turns t
    JOIN batch_change_agent_messages m ON m.id = t.message_id
    CROSS JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(t.tool_calls) = 'array' THEN t.tool_calls ELSE '[]'::jsonb END
    ) WITH ORDINALITY AS call(value, ordinality)

    UNION ALL

    SELECT
        m.tenant_id,
        m.thread_id,
        m.id,
        t.id,
        m.sequence,
        t.sequence,
        t.created_at,
        400000 + result.ordinality,
        'tool_result',
        result.value,
        t.stats
    FROM batch_change_agent_turns t
    JOIN batch_change_agent_messages m ON m.id = t.message_id
    CROSS JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(t.tool_results) = 'array' THEN t.tool_results ELSE '[]'::jsonb END
    ) WITH ORDINALITY AS result(value, ordinality)

    UNION ALL

    -- MarkMessageCompleted historically stored AgentResult.Output separately
    -- from turns. Usually it duplicates the final assistant turn, but preserve
    -- it when an older persistence failure left the durable turns incomplete.
    SELECT
        m.tenant_id,
        m.thread_id,
        m.id,
        (SELECT COALESCE(MAX(t.id), 0) FROM batch_change_agent_turns t) + m.id,
        m.sequence,
        COALESCE((SELECT MAX(t.sequence) FROM batch_change_agent_turns t WHERE t.message_id = m.id), 0) + 1,
        m.updated_at,
        200000,
        'assistant_text',
        jsonb_build_object('text', m.answer),
        '{}'::jsonb
    FROM batch_change_agent_messages m
    WHERE COALESCE(m.answer, '') <> ''
      AND m.answer IS DISTINCT FROM (
          SELECT t.reasoning
          FROM batch_change_agent_turns t
          WHERE t.message_id = m.id
            AND t.role = 'assistant'
          ORDER BY t.sequence DESC, t.id DESC
          LIMIT 1
      )
), ordered AS (
    SELECT
        candidates.*,
        ROW_NUMBER() OVER (
            PARTITION BY thread_id
            ORDER BY message_sequence, turn_sequence, turn_id, part_order
        ) * 1000 AS entry_sequence,
        ROW_NUMBER() OVER (
            PARTITION BY turn_id
            ORDER BY part_order DESC
        ) AS reverse_part_order
    FROM candidates
)
INSERT INTO batch_change_agent_thread_entries
    (tenant_id, thread_id, sequence, message_id, turn_id, kind, payload, stats, created_at)
SELECT tenant_id, thread_id, entry_sequence, message_id, turn_id, kind, payload,
    CASE WHEN reverse_part_order = 1 THEN stats ELSE '{}'::jsonb END,
    created_at
FROM ordered
ON CONFLICT (tenant_id, thread_id, sequence) DO NOTHING;

-- Preserve terminal run failures in the visible transcript.
WITH terminal_errors AS (
    SELECT
        m.*,
        ROW_NUMBER() OVER (PARTITION BY m.thread_id ORDER BY m.created_at, m.id) AS error_order
    FROM batch_change_agent_messages m
    WHERE (m.error IS NOT NULL AND m.error <> '') OR m.status = 'cancelled'
)
INSERT INTO batch_change_agent_thread_entries
    (tenant_id, thread_id, sequence, message_id, turn_id, kind, payload, created_at)
SELECT
    m.tenant_id,
    m.thread_id,
    COALESCE((SELECT MAX(e.sequence) FROM batch_change_agent_thread_entries e WHERE e.message_id = m.id), 0) + 500,
    m.id,
    COALESCE((SELECT MAX(e.turn_id) FROM batch_change_agent_thread_entries e WHERE e.thread_id = m.thread_id), 0) + m.error_order,
    'error',
    jsonb_build_object('status', m.status, 'message', COALESCE(NULLIF(m.error, ''), 'question was cancelled')),
    m.updated_at
FROM terminal_errors m
ON CONFLICT (tenant_id, thread_id, sequence) DO NOTHING;

-- Backfill compactions as transcript entries. Their cutoffs target the final
-- entry in the legacy turn named by up_to_turn_id (or the closest earlier turn
-- when that turn produced no entries). Each compaction is placed directly after
-- its cutoff entry, where it happened chronologically, so it renders inside the
-- question it belongs to. Entries above sit on multiples of 1000 and errors on
-- +500, so cutoff.sequence + n stays before the next entry.
WITH compacted AS (
    SELECT
        c.*,
        cutoff.id AS cutoff_entry_id,
        cutoff.sequence AS cutoff_sequence,
        ROW_NUMBER() OVER (PARTITION BY c.thread_id ORDER BY c.created_at, c.id) AS compaction_order,
        ROW_NUMBER() OVER (PARTITION BY cutoff.id ORDER BY c.created_at, c.id) AS cutoff_order
    FROM batch_change_agent_thread_compactions c
    JOIN LATERAL (
        SELECT e.id, e.sequence
        FROM batch_change_agent_thread_entries e
        WHERE e.thread_id = c.thread_id AND e.turn_id <= c.up_to_turn_id
        ORDER BY e.sequence DESC
        LIMIT 1
    ) cutoff ON TRUE
)
INSERT INTO batch_change_agent_thread_entries
    (tenant_id, thread_id, sequence, turn_id, kind, payload, compacted_through_entry_id, stats, created_at)
SELECT
    c.tenant_id,
    c.thread_id,
    c.cutoff_sequence + c.cutoff_order,
    COALESCE((SELECT MAX(e.turn_id) FROM batch_change_agent_thread_entries e WHERE e.thread_id = c.thread_id), 0) + c.compaction_order,
    'compaction',
    jsonb_build_object('summary', c.summary, 'cumulative_stats', c.stats, 'summary_stats', c.summary_stats),
    c.cutoff_entry_id,
    c.summary_stats,
    c.created_at
FROM compacted c
ON CONFLICT (tenant_id, thread_id, sequence) DO NOTHING;

-- Make thread state the source of truth for current execution. This migration
-- is NOT rolling-upgrade safe: it drops the legacy message/turn tables and the
-- message_id columns below, so workers built before it fail once it has run.
-- Batch change agents are a beta feature and a downtime upgrade is accepted.
WITH active_messages AS (
    SELECT DISTINCT ON (m.thread_id) m.thread_id, m.id
    FROM batch_change_agent_messages m
    WHERE m.status = 'processing'
    ORDER BY m.thread_id, m.id DESC
)
UPDATE batch_change_agent_threads t
SET state = CASE
        WHEN EXISTS (
            SELECT 1
            FROM batch_change_agent_tool_approvals approval
            WHERE approval.message_id = active.id AND approval.state = 'pending'
        ) OR COALESCE((
            SELECT latest.tool_calls
            FROM batch_change_agent_turns latest
            WHERE latest.message_id = active.id
            ORDER BY latest.sequence DESC, latest.id DESC
            LIMIT 1
        ), '[]'::jsonb) @> '[{"function":{"name":"ask_user"}}]'::jsonb
            THEN 'waiting_for_user'
        ELSE 'processing'
    END,
    active_message_id = active.id
FROM active_messages active
WHERE active.thread_id = t.id AND t.active_message_id IS NULL;

-- Cut execution correlation over to the canonical transcript before removing
-- the legacy message/turn hierarchy. A job is one dbworker attempt for a
-- thread, triggered by a user-message entry; a paused thread can therefore
-- have multiple jobs with the same trigger entry over its lifetime.
ALTER TABLE batch_change_agent_jobs
    ADD COLUMN IF NOT EXISTS thread_id INTEGER REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS trigger_entry_id BIGINT REFERENCES batch_change_agent_thread_entries(id) ON DELETE CASCADE;

WITH triggers AS (
    SELECT m.id AS message_id, m.thread_id, MIN(e.id) AS trigger_entry_id
    FROM batch_change_agent_messages m
    JOIN batch_change_agent_thread_entries e ON e.message_id = m.id AND e.kind = 'user_message'
    GROUP BY m.id, m.thread_id
)
UPDATE batch_change_agent_jobs j
SET thread_id = trigger.thread_id,
    trigger_entry_id = trigger.trigger_entry_id
FROM triggers trigger
WHERE j.message_id = trigger.message_id AND (j.thread_id IS NULL OR j.trigger_entry_id IS NULL);

ALTER TABLE batch_change_agent_jobs
    ALTER COLUMN thread_id SET NOT NULL,
    ALTER COLUMN trigger_entry_id SET NOT NULL;

ALTER TABLE batch_change_agent_tool_approvals
    ADD COLUMN IF NOT EXISTS thread_entry_id BIGINT REFERENCES batch_change_agent_thread_entries(id) ON DELETE CASCADE;

WITH calls AS (
    SELECT DISTINCT ON (approval.id) approval.id AS approval_id, e.id AS thread_entry_id
    FROM batch_change_agent_tool_approvals approval
    JOIN batch_change_agent_thread_entries e
      ON e.message_id = approval.message_id
     AND e.kind = 'tool_call'
     AND e.payload->>'id' = approval.tool_call_id
    ORDER BY approval.id, e.sequence DESC
)
UPDATE batch_change_agent_tool_approvals approval
SET thread_entry_id = call.thread_entry_id
FROM calls call
WHERE approval.id = call.approval_id AND approval.thread_entry_id IS NULL;

ALTER TABLE batch_change_agent_tool_approvals
    ALTER COLUMN thread_entry_id SET NOT NULL;

ALTER TABLE batch_change_agent_spec_drafts
    ADD COLUMN IF NOT EXISTS trigger_entry_id BIGINT REFERENCES batch_change_agent_thread_entries(id) ON DELETE SET NULL;

WITH triggers AS (
    SELECT draft.id AS draft_id, MIN(e.id) AS trigger_entry_id
    FROM batch_change_agent_spec_drafts draft
    JOIN batch_change_agent_thread_entries e ON e.message_id = draft.message_id AND e.kind = 'user_message'
    GROUP BY draft.id
)
UPDATE batch_change_agent_spec_drafts draft
SET trigger_entry_id = trigger.trigger_entry_id
FROM triggers trigger
WHERE draft.id = trigger.draft_id AND draft.trigger_entry_id IS NULL;

ALTER TABLE batch_change_agent_threads
    ADD COLUMN IF NOT EXISTS active_entry_id BIGINT REFERENCES batch_change_agent_thread_entries(id) ON DELETE SET NULL;

WITH triggers AS (
    SELECT t.id AS thread_id, MIN(e.id) AS trigger_entry_id
    FROM batch_change_agent_threads t
    JOIN batch_change_agent_thread_entries e ON e.message_id = t.active_message_id AND e.kind = 'user_message'
    GROUP BY t.id
)
UPDATE batch_change_agent_threads t
SET active_entry_id = trigger.trigger_entry_id
FROM triggers trigger
WHERE t.id = trigger.thread_id AND t.active_entry_id IS NULL;

DROP INDEX IF EXISTS batch_change_agent_jobs_message_id_idx;
DROP INDEX IF EXISTS batch_change_agent_spec_drafts_message_id_idx;
DROP INDEX IF EXISTS batch_change_agent_tool_approvals_message_tool_call_idx;
DROP INDEX IF EXISTS batch_change_agent_thread_entries_message_id_idx;

ALTER TABLE batch_change_agent_jobs DROP COLUMN IF EXISTS message_id;
ALTER TABLE batch_change_agent_tool_approvals DROP COLUMN IF EXISTS message_id;
ALTER TABLE batch_change_agent_spec_drafts DROP COLUMN IF EXISTS message_id;
ALTER TABLE batch_change_agent_threads DROP COLUMN IF EXISTS active_message_id;
ALTER TABLE batch_change_agent_thread_entries DROP COLUMN IF EXISTS message_id;

IF EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = 'batch_change_agent_thread_entries'::regclass
          AND attname = 'turn_id'
          AND NOT attisdropped
    ) THEN
    ALTER TABLE batch_change_agent_thread_entries RENAME COLUMN turn_id TO group_id;
END IF;

ALTER TABLE batch_change_agent_thread_entries
    DROP CONSTRAINT IF EXISTS batch_change_agent_thread_entries_turn_id_check;
ALTER TABLE batch_change_agent_thread_entries
    DROP CONSTRAINT IF EXISTS batch_change_agent_thread_entries_group_id_check;
ALTER TABLE batch_change_agent_thread_entries
    ADD CONSTRAINT batch_change_agent_thread_entries_group_id_check CHECK (group_id > 0);

COMMENT ON COLUMN batch_change_agent_thread_entries.group_id IS
    'Groups adjacent transcript entries that reconstruct one provider message; it does not reference a separate turn entity.';

CREATE INDEX IF NOT EXISTS batch_change_agent_jobs_thread_id_idx
    ON batch_change_agent_jobs (thread_id, tenant_id);
CREATE INDEX IF NOT EXISTS batch_change_agent_jobs_trigger_entry_id_idx
    ON batch_change_agent_jobs (trigger_entry_id, tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_tool_approvals_entry_idx
    ON batch_change_agent_tool_approvals (tenant_id, thread_entry_id);
CREATE INDEX IF NOT EXISTS batch_change_agent_spec_drafts_trigger_entry_id_idx
    ON batch_change_agent_spec_drafts (trigger_entry_id, tenant_id)
    WHERE trigger_entry_id IS NOT NULL;

DROP TABLE IF EXISTS batch_change_agent_thread_compactions;
DROP TABLE IF EXISTS batch_change_agent_turns;
DROP TABLE IF EXISTS batch_change_agent_messages;

END
$migration$;
